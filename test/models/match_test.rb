# frozen_string_literal: true

require 'test_helper'

class MatchTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test 'finished score correction does not finalize twice' do
    match = matches(:tournament_1_bout_1000)
    match.update_columns(mat_id: nil, finalized_at: nil)
    enqueued_jobs = 0
    match.define_singleton_method(:enqueue_post_finalize_jobs!) do
      enqueued_jobs += 1
      true
    end

    match.update!(winner_id: match.w1, win_type: 'Decision', score: '3-1', finished: 1)

    assert_equal 1, enqueued_jobs
    assert_not_nil match.reload.finalized_at

    match.update!(score: '4-1')

    assert_equal 1, enqueued_jobs
  end

  test 'finalizing queue1 promotes queue2 to queue1 before background jobs run' do
    ActiveJob::Base.queue_adapter = :test
    mat = mats(:one)
    queue1_match = matches(:tournament_1_bout_1000)
    queue2_match = matches(:tournament_1_bout_1001)
    mat.update!(queue1: queue1_match.id, queue2: queue2_match.id, queue3: nil, queue4: nil)
    queue1_match.update_columns(mat_id: mat.id, finalized_at: nil, finished: nil, winner_id: nil, win_type: nil, score: nil)
    queue2_match.update_columns(mat_id: mat.id)

    assert_enqueued_with(job: AdvanceWrestlerJob, args: [[queue1_match.id], queue1_match.tournament_id]) do
      assert_enqueued_with(job: FillBoutBoardJob, args: [queue1_match.tournament_id]) do
        queue1_match.update!(winner_id: queue1_match.w1, win_type: 'Decision', score: '3-1', finished: 1)
      end
    end

    assert_equal queue2_match.id, mat.reload.queue1
    assert_nil mat.queue2
    assert_nil queue1_match.reload.mat_id
  ensure
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear if ActiveJob::Base.queue_adapter.respond_to?(:enqueued_jobs)
    ActiveJob::Base.queue_adapter = :inline
  end

  test 'finalizing queue2 leaves queue1 unchanged before background jobs run' do
    ActiveJob::Base.queue_adapter = :test
    mat = mats(:one)
    queue1_match = matches(:tournament_1_bout_1000)
    queue2_match = matches(:tournament_1_bout_1001)
    mat.update!(queue1: queue1_match.id, queue2: queue2_match.id, queue3: nil, queue4: nil)
    queue1_match.update_columns(mat_id: mat.id)
    queue2_match.update_columns(mat_id: mat.id, finalized_at: nil, finished: nil, winner_id: nil, win_type: nil, score: nil)

    assert_enqueued_with(job: AdvanceWrestlerJob, args: [[queue2_match.id], queue2_match.tournament_id]) do
      assert_enqueued_with(job: FillBoutBoardJob, args: [queue2_match.tournament_id]) do
        queue2_match.update!(winner_id: queue2_match.w1, win_type: 'Decision', score: '3-1', finished: 1)
      end
    end

    mat.reload
    assert_equal queue1_match.id, mat.queue1
    assert_equal queue2_match.id, mat.queue2
  ensure
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear if ActiveJob::Base.queue_adapter.respond_to?(:enqueued_jobs)
    ActiveJob::Base.queue_adapter = :inline
  end

  test 'Match should not be valid if win type is a pin and a score is provided' do
    create_double_elim_tournament_single_weight(14, 'Regular Double Elimination 1-8')
    matches = @tournament.matches.reload
    matches.select { |m| m.round == 1 }
    match = matches.first
    match.winner_id = match.w1
    match.finished = 1
    match.win_type = 'Pin'
    match.score = '0-0'
    match.save
    assert_not match.valid?
  end
  test 'Match should not be valid if win type is a pin and an incorrect time is provided' do
    create_double_elim_tournament_single_weight(14, 'Regular Double Elimination 1-8')
    matches = @tournament.matches.reload
    matches.select { |m| m.round == 1 }
    match = matches.first
    match.winner_id = match.w1
    match.finished = 1
    match.win_type = 'Pin'
    match.score = ':03'
    match.save
    assert_not match.valid?
  end
  test 'Match should be valid if win type is a pin and a correct time is provided' do
    create_double_elim_tournament_single_weight(14, 'Regular Double Elimination 1-8')
    matches = @tournament.matches.reload
    matches.select { |m| m.round == 1 }
    match = matches.first
    match.winner_id = match.w1
    match.finished = 1
    match.win_type = 'Pin'
    match.score = '0:03'
    match.save
    assert match.valid?
  end
  test 'Match should be valid if win type is a pin and a correct time is provided with an extra 0' do
    create_double_elim_tournament_single_weight(14, 'Regular Double Elimination 1-8')
    matches = @tournament.matches.reload
    matches.select { |m| m.round == 1 }
    match = matches.first
    match.winner_id = match.w1
    match.finished = 1
    match.win_type = 'Pin'
    match.score = '00:03'
    match.save
    assert match.valid?
  end
  test 'Match should be valid if win type is a decision and a correct score is provided' do
    create_double_elim_tournament_single_weight(14, 'Regular Double Elimination 1-8')
    matches = @tournament.matches.reload
    matches.select { |m| m.round == 1 }
    match = matches.first
    match.winner_id = match.w1
    match.finished = 1
    match.win_type = 'Decision'
    match.score = '1-0'
    match.save
    assert match.valid?
  end
  test 'Match should not be valid if win type is a decision and a time is provided' do
    create_double_elim_tournament_single_weight(14, 'Regular Double Elimination 1-8')
    matches = @tournament.matches.reload
    matches.select { |m| m.round == 1 }
    match = matches.first
    match.winner_id = match.w1
    match.finished = 1
    match.win_type = 'Decision'
    match.score = '1:00'
    match.save
    assert_not match.valid?
  end
  test 'Match should not be valid if win type is a bye and a score is provided' do
    create_double_elim_tournament_single_weight(14, 'Regular Double Elimination 1-8')
    matches = @tournament.matches.reload
    matches.select { |m| m.round == 1 }
    match = matches.first
    match.winner_id = match.w1
    match.finished = 1
    match.win_type = 'BYE'
    match.score = '1:00'
    match.save
    assert_not match.valid?
  end
  test 'Match should be valid if win type is a bye and a score is not provided' do
    create_double_elim_tournament_single_weight(14, 'Regular Double Elimination 1-8')
    matches = @tournament.matches.reload
    matches.select { |m| m.round == 1 }
    match = matches.first
    match.winner_id = match.w1
    match.finished = 1
    match.win_type = 'BYE'
    match.score = ''
    match.save
    assert match.valid?
  end
  test 'Match should not be valid if an incorrect win type is given' do
    create_double_elim_tournament_single_weight(14, 'Regular Double Elimination 1-8')
    matches = @tournament.matches.reload
    matches.select { |m| m.round == 1 }
    match = matches.first
    match.winner_id = match.w1
    match.finished = 1
    match.win_type = 'TEST'
    match.save
    assert_not match.valid?
  end
  test 'Match should not be valid when the winner is not in the match' do
    create_double_elim_tournament_single_weight(14, 'Regular Double Elimination 1-8')
    match = @tournament.matches.reload.first
    outsider = match.weight.wrestlers.find { |wrestler| [match.w1, match.w2].exclude?(wrestler.id) }
    match.winner_id = outsider.id
    match.finished = 1
    match.win_type = 'Decision'
    match.score = '1-0'

    assert_not match.valid?
    assert_includes match.errors[:winner_id], 'must be one of the wrestlers in the match'
  end
  test 'Match should not be valid if an incorrect bracket position is given' do
    create_double_elim_tournament_single_weight(14, 'Regular Double Elimination 1-8')
    matches = @tournament.matches.reload
    matches.select { |m| m.round == 1 }
    match = matches.first
    match.bracket_position = 'TEST'
    match.save
    assert_not match.valid?
  end
  test 'Match should not be valid if an incorrect overtime_type is given' do
    create_double_elim_tournament_single_weight(14, 'Regular Double Elimination 1-8')
    matches = @tournament.matches.reload
    matches.select { |m| m.round == 1 }
    match = matches.first
    match.overtime_type = 'TEST'
    match.save
    assert_not match.valid?
  end

  test 'Match pin_time_in_seconds should properly handle format mm:ss' do
    create_double_elim_tournament_single_weight(14, 'Regular Double Elimination 1-8')
    matches = @tournament.matches.reload
    match = matches.first
    match.winner_id = match.w1
    match.finished = 1
    match.win_type = 'Pin'
    match.score = '02:03'
    match.save
    assert_equal 123, match.reload.pin_time_in_seconds
  end

  test 'Match pin_time_in_seconds should properly handle format m:ss' do
    create_double_elim_tournament_single_weight(14, 'Regular Double Elimination 1-8')
    matches = @tournament.matches.reload
    match = matches.first
    match.winner_id = match.w1
    match.finished = 1
    match.win_type = 'Pin'
    match.score = '2:03'
    match.save
    assert_equal 123, match.reload.pin_time_in_seconds
  end

  test 'Match gets a finished_at value when finished changes and is 1' do
    create_double_elim_tournament_single_weight(14, 'Regular Double Elimination 1-8')
    matches = @tournament.matches.reload
    match = matches.first
    match.winner_id = match.w1
    match.finished = 1
    match.win_type = 'Pin'
    match.score = '2:03'
    match.save
    # Assert finished_at is not nil
    assert_not_nil match.reload.finished_at, 'finished_at should not be nil when finished is set to 1'
  end

  test 'Match gets a finished_at value when finished changes and is 1 and finished_at does not change when winner id is changed' do
    create_double_elim_tournament_single_weight(14, 'Regular Double Elimination 1-8')
    matches = @tournament.matches.reload
    match = matches.first
    match.winner_id = match.w1
    match.finished = 1
    match.win_type = 'Pin'
    match.score = '2:03'
    match.save

    finished_at = match.reload.finished_at

    # Assert finished_at is not nil
    assert_not_nil finished_at, 'finished_at should not be nil when finished is set to 1'

    match.winner_id = match.w2
    match.save

    # Assert finished_at did not change
    assert_equal match.reload.finished_at, finished_at
  end
end
