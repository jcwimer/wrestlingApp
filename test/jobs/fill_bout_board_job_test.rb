# frozen_string_literal: true

require 'test_helper'

class FillBoutBoardJobTest < ActiveJob::TestCase
  setup do
    @tournament = tournaments(:one)
    @mat = mats(:one)
    @queue1_match = matches(:tournament_1_bout_1000)
    @queue2_match = matches(:tournament_1_bout_1001)
    @mat.update!(queue1: @queue1_match.id, queue2: @queue2_match.id, queue3: nil, queue4: nil)
    @queue1_match.update_columns(mat_id: @mat.id)
    @queue2_match.update_columns(mat_id: @mat.id)
  end

  test 'removes finished matches from queues and refills open slots' do
    @queue2_match.update_columns(finished: 1, winner_id: @queue2_match.w1, win_type: 'Decision', score: '3-1')

    FillBoutBoardJob.perform_now(@tournament.id)

    @mat.reload
    assert_equal @queue1_match.id, @mat.queue1
    assert_not_includes @mat.queue_match_ids.compact, @queue2_match.id
  end
end
