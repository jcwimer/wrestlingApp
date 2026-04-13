require "test_helper"

class MatScoreboardStateTest < ActiveSupport::TestCase
  setup do
    @mat = mats(:one)
    @queue1_match = matches(:tournament_1_bout_1000)
    @queue2_match = matches(:tournament_1_bout_1001)
    Rails.cache.clear
    @mat.update!(queue1: @queue1_match.id, queue2: @queue2_match.id, queue3: nil, queue4: nil)
  end

  test "scoreboard_payload falls back to queue1 when no selected match exists" do
    payload = @mat.scoreboard_payload

    assert_equal @mat.id, payload[:mat_id]
    assert_equal @queue1_match.id, payload[:queue1_match_id]
    assert_equal @queue1_match.bout_number, payload[:queue1_bout_number]
    assert_nil payload[:selected_match_id]
    assert_nil payload[:selected_bout_number]
    assert_nil payload[:last_match_result]
  end

  test "selected_scoreboard_match clears stale cached match ids" do
    stale_match = matches(:tournament_1_bout_2000)
    @mat.set_selected_scoreboard_match!(stale_match)

    assert_nil @mat.selected_scoreboard_match
    assert_nil Rails.cache.read("tournament:#{@mat.tournament_id}:mat:#{@mat.id}:scoreboard_selection")
  end

  test "scoreboard_payload returns selected match when selection is valid" do
    @mat.set_selected_scoreboard_match!(@queue2_match)

    payload = @mat.scoreboard_payload

    assert_equal @queue2_match.id, payload[:selected_match_id]
    assert_equal @queue2_match.bout_number, payload[:selected_bout_number]
  end

  test "scoreboard_payload includes last match result when present" do
    @mat.set_last_match_result!("106 lbs - Winner Decision Loser 3-1")

    payload = @mat.scoreboard_payload

    assert_equal "106 lbs - Winner Decision Loser 3-1", payload[:last_match_result]
  end

  test "scoreboard_payload handles empty queue" do
    @mat.update!(queue1: nil, queue2: nil, queue3: nil, queue4: nil)

    payload = @mat.scoreboard_payload

    assert_nil payload[:queue1_match_id]
    assert_nil payload[:queue1_bout_number]
    assert_nil payload[:selected_match_id]
    assert_nil payload[:selected_bout_number]
  end

  test "scoreboard_payload falls back to new queue1 after selected queue1 leaves the queue" do
    @mat.set_selected_scoreboard_match!(@queue1_match)
    @queue1_match.update!(winner_id: @queue1_match.w1, win_type: "Decision", score: "3-1", finished: 1)

    @mat.advance_queue!(@queue1_match)
    payload = @mat.reload.scoreboard_payload

    assert_equal @queue2_match.id, payload[:queue1_match_id]
    assert_equal @queue2_match.bout_number, payload[:queue1_bout_number]
    assert_nil payload[:selected_match_id]
    assert_nil payload[:selected_bout_number]
    assert_nil Rails.cache.read("tournament:#{@mat.tournament_id}:mat:#{@mat.id}:scoreboard_selection")
  end

  test "scoreboard_payload keeps selected match when queue advances and selection remains queued" do
    @mat.set_selected_scoreboard_match!(@queue2_match)
    @queue1_match.update!(winner_id: @queue1_match.w1, win_type: "Decision", score: "3-1", finished: 1)

    @mat.advance_queue!(@queue1_match)
    payload = @mat.reload.scoreboard_payload

    assert_equal @queue2_match.id, payload[:queue1_match_id]
    assert_equal @queue2_match.bout_number, payload[:queue1_bout_number]
    assert_equal @queue2_match.id, payload[:selected_match_id]
    assert_equal @queue2_match.bout_number, payload[:selected_bout_number]
  end
end
