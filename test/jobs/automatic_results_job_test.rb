# frozen_string_literal: true

require 'test_helper'

class AutomaticResultsJobTest < ActiveJob::TestCase
  test 'finishes one result and lets queued advancement continue the weight' do
    tournament = tournaments(:one)
    weight = tournament.weights.create!(max: 999)
    wrestlers = %w[First Second Third].map do |name|
      weight.wrestlers.create!(name: name, school: schools(:one))
    end
    wrestlers.first.update_column(:auto_medical_forfeit, true)
    match_attributes = { tournament: tournament, bracket_position: 'Quarter', round: 1, finished: 0, score: '' }
    first = weight.matches.create!(match_attributes.merge(w1: wrestlers[0].id, w2: wrestlers[1].id, bracket_position_number: 1))
    second = weight.matches.create!(match_attributes.merge(w1: wrestlers[2].id, w2: wrestlers[0].id, bracket_position_number: 2))
    semifinal = weight.matches.create!(tournament: tournament, bracket_position: 'Semis', bracket_position_number: 1,
                                       round: 2, finished: 0)

    assert_enqueued_jobs 1, only: AdvanceWrestlerJob do
      assert_enqueued_jobs 1, only: FillBoutBoardJob do
        AutomaticResultsJob.perform_now(weight)
      end
    end

    assert_equal wrestlers[1].id, first.reload.winner_id
    assert_equal 'Medical Forfeit', first.win_type
    assert_not_nil first.finalized_at
    assert_equal 0, second.reload.finished
    assert_nil second.winner_id
    assert_nil semifinal.reload.w1
    assert_nil semifinal.w2
    first_finalized_at = first.finalized_at

    perform_enqueued_jobs while enqueued_jobs.any?

    [first, second].each do |match|
      match.reload
      assert_equal 'Medical Forfeit', match.win_type
      assert_equal 1, match.finished
      assert_not_nil match.finalized_at
    end
    assert_equal wrestlers[2].id, second.winner_id
    assert_equal [wrestlers[1].id, wrestlers[2].id], [semifinal.reload.w1, semifinal.w2]
    assert_equal first_finalized_at, first.reload.finalized_at
    finalization_times = [first.finalized_at, second.finalized_at]

    assert_no_enqueued_jobs { AutomaticResultsJob.perform_now(weight) }

    assert_equal finalization_times, [first.reload.finalized_at, second.reload.finalized_at]
  end
end
