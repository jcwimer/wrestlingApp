# frozen_string_literal: true

require 'test_helper'
require 'mocha/minitest'

module BracketAdvancement
  class AutomaticResultsTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

    setup do
      @tournament = tournaments(:one)
      @weight = Weight.create!(tournament: @tournament, max: 999)
      @other_weight = Weight.create!(tournament: @tournament, max: 998)
      @wrestler1 = wrestler('First')
      @wrestler2 = wrestler('Second')
      @other_wrestler = wrestler('Other', @other_weight)
      clear_enqueued_jobs
    end

    test 'marks each side of a single bye as the winner' do
      [[@wrestler1, { w1: @wrestler1.id, loser2_name: 'BYE' }],
       [@wrestler2, { w2: @wrestler2.id, loser1_name: 'BYE' }]].each do |wrestler, slots|
        wrestler.update_column(:auto_medical_forfeit, true)
        match = build_match(**slots)

        BracketAdvancement::AutomaticResults.new(@weight).call

        assert_equal 1, match.reload.finished
        assert_equal wrestler.id, match.winner_id
        assert_equal 'BYE', match.win_type
        wrestler.update_column(:auto_medical_forfeit, false)
      end
    end

    test 'medical forfeits award the opponent when exactly one wrestler is flagged' do
      [[@wrestler1, @wrestler2], [@wrestler2, @wrestler1]].each do |flagged, opponent|
        flagged.update_column(:auto_medical_forfeit, true)
        match = build_match(w1: @wrestler1.id, w2: @wrestler2.id)

        BracketAdvancement::AutomaticResults.new(@weight).call

        assert_equal 1, match.reload.finished
        assert_equal opponent.id, match.winner_id
        assert_equal 'Medical Forfeit', match.win_type
        flagged.update_column(:auto_medical_forfeit, false)
      end
    end

    test 'both flagged wrestlers produce a stable medical forfeit winner' do
      Wrestler.where(id: [@wrestler1.id, @wrestler2.id]).update_all(auto_medical_forfeit: true)
      match = build_match(w1: @wrestler1.id, w2: @wrestler2.id)
      Array.any_instance.expects(:sample).returns(@wrestler2)

      service = BracketAdvancement::AutomaticResults.new(@weight)
      service.call
      enqueued_jobs_after_first_call = enqueued_jobs.size
      service.call

      assert_equal @wrestler2.id, match.reload.winner_id
      assert_equal 'Medical Forfeit', match.win_type
      assert_equal enqueued_jobs_after_first_call, enqueued_jobs.size
    end

    test 'finishes only the first eligible result on each call' do
      third_wrestler = wrestler('Third')
      unflagged_match = build_match(w1: @wrestler2.id, w2: third_wrestler.id)
      @wrestler1.update_column(:auto_medical_forfeit, true)
      first_eligible = build_match(w1: @wrestler1.id, w2: @wrestler2.id)
      second_eligible = build_match(w1: third_wrestler.id, loser2_name: 'BYE')
      service = BracketAdvancement::AutomaticResults.new(@weight)
      performed_jobs_before = performed_jobs.size

      service.call

      first_eligible.reload
      assert_not_equal 1, unflagged_match.reload.finished
      assert_equal 1, first_eligible.finished
      assert_equal @wrestler2.id, first_eligible.winner_id
      assert_not_equal 1, second_eligible.reload.finished
      first_winner_id = first_eligible.winner_id
      first_finalized_at = first_eligible.finalized_at
      jobs_after_first_call = enqueued_jobs.size

      service.call

      assert_equal 1, second_eligible.reload.finished
      assert_equal 'BYE', second_eligible.win_type
      assert_equal 1, first_eligible.reload.finished
      assert_equal first_winner_id, first_eligible.winner_id
      assert_equal first_finalized_at, first_eligible.finalized_at
      jobs_after_second_call = enqueued_jobs.size

      service.call

      assert_equal jobs_after_second_call, enqueued_jobs.size
      assert_operator jobs_after_second_call, :>, jobs_after_first_call
      assert_equal performed_jobs_before, performed_jobs.size
    end

    test 'leaves unflagged contested, unresolved, and already finished matches unchanged' do
      contested = build_match(w1: @wrestler1.id, w2: @wrestler2.id)
      unresolved = build_match(w1: @wrestler1.id, loser2_name: nil)
      finished = build_match(w1: @wrestler1.id, w2: @wrestler2.id, finished: 1, winner_id: @wrestler1.id,
                             win_type: 'Decision', score: '3-1')

      BracketAdvancement::AutomaticResults.new(@weight).call

      assert_not_equal 1, contested.reload.finished
      assert_not_equal 1, unresolved.reload.finished
      assert_equal 'Decision', finished.reload.win_type
      assert_equal '3-1', finished.score
      assert_nil finished.finalized_at
    end

    test 'only processes the supplied weight and ignores an unflagged wrestler' do
      other_match = build_match(weight: @other_weight, w1: @other_wrestler.id, w2: nil, loser2_name: 'BYE')
      regular_match = build_match(w1: @wrestler1.id, w2: @wrestler2.id)
      false_flag_bye = build_match(w1: @wrestler1.id, w2: nil, loser2_name: 'BYE')
      @other_wrestler.update_column(:auto_medical_forfeit, true)

      BracketAdvancement::AutomaticResults.new(@weight).call

      assert_not_equal 1, regular_match.reload.finished
      assert_not_equal 1, other_match.reload.finished
      assert_equal 1, false_flag_bye.reload.finished
      assert_equal 'BYE', false_flag_bye.win_type
      assert_equal @wrestler1.id, false_flag_bye.winner_id
    end

    test 'clears scoring fields and callback finalizes and enqueues jobs without advancing inline' do
      match = build_match(w1: @wrestler1.id, w2: @wrestler2.id, bracket_position: 'Quarter',
                          bracket_position_number: 1, score: '8-2', overtime_type: 'SV-1')
      next_match = build_match(bracket_position: 'Semis', bracket_position_number: 1, round: 2)
      @wrestler1.update_column(:auto_medical_forfeit, true)
      @wrestler2.update_column(:auto_medical_forfeit, false)

      performed_jobs_before = performed_jobs.size
      BracketAdvancement::AutomaticResults.new(@weight).call

      match.reload
      assert_equal '', match.score
      assert_nil match.overtime_type
      assert_not_nil match.finished_at
      assert_not_nil match.finalized_at
      assert_equal performed_jobs_before, performed_jobs.size
      assert_enqueued_with(job: AdvanceWrestlerJob, args: [[match.id], @tournament.id])
      assert_enqueued_with(job: FillBoutBoardJob, args: [@tournament.id])
      assert_nil next_match.reload.w1
      assert_nil next_match.w2
    end

    test 'finishes a double bye with no winner and queues callback jobs' do
      match = build_match(w1: nil, w2: nil, loser1_name: 'BYE', loser2_name: 'BYE')

      assert_enqueued_with(job: AdvanceWrestlerJob, args: [[match.id], @tournament.id]) do
        assert_enqueued_with(job: FillBoutBoardJob, args: [@tournament.id]) do
          BracketAdvancement::AutomaticResults.new(@weight).call
        end
      end

      assert_equal 1, match.reload.finished
      assert_nil match.winner_id
      assert_equal 'BYE', match.win_type
      assert_not_nil match.finished_at
    end

    private

    def wrestler(name, weight = @weight)
      Wrestler.create!(name:, weight:, school: schools(:one))
    end

    def build_match(weight: @weight, **attributes)
      Match.create!({ tournament: @tournament, weight:, bracket_position: 'Bracket', round: 1, finished: 0,
                      score: '', overtime_type: '' }.merge(attributes))
    end
  end
end
