require "test_helper"
require "json"

class MatScoreboardBroadcastTest < ActiveSupport::TestCase
  test "set_selected_scoreboard_match broadcasts updated payload" do
    mat = mats(:one)
    queue1_match = matches(:tournament_1_bout_1000)
    selected_match = matches(:tournament_1_bout_1001)
    mat.update!(queue1: queue1_match.id, queue2: selected_match.id, queue3: nil, queue4: nil)

    stream = MatScoreboardChannel.broadcasting_for(mat)
    clear_streams(stream)

    mat.set_selected_scoreboard_match!(selected_match)

    payload = JSON.parse(broadcasts_for(stream).last)
    assert_equal mat.id, payload["mat_id"]
    assert_equal queue1_match.id, payload["queue1_match_id"]
    assert_equal queue1_match.bout_number, payload["queue1_bout_number"]
    assert_equal selected_match.id, payload["selected_match_id"]
    assert_equal selected_match.bout_number, payload["selected_bout_number"]
  end

  test "set_last_match_result broadcasts updated payload" do
    mat = mats(:one)
    queue1_match = matches(:tournament_1_bout_1000)
    mat.update!(queue1: queue1_match.id, queue2: nil, queue3: nil, queue4: nil)

    stream = MatScoreboardChannel.broadcasting_for(mat)
    clear_streams(stream)

    mat.set_last_match_result!("106 lbs - Winner Decision Loser 3-1")

    payload = JSON.parse(broadcasts_for(stream).last)
    assert_equal "106 lbs - Winner Decision Loser 3-1", payload["last_match_result"]
    assert_equal queue1_match.id, payload["queue1_match_id"]
  end

  private

  def broadcasts_for(stream)
    ActionCable.server.pubsub.broadcasts(stream)
  end

  def clear_streams(*streams)
    ActionCable.server.pubsub.clear
    streams.each do |stream|
      broadcasts_for(stream).clear
    end
  end
end
