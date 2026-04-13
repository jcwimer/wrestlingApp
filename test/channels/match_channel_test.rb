require "test_helper"

class MatchChannelTest < ActionCable::Channel::TestCase
  setup do
    @match = matches(:tournament_1_bout_1000)
    Rails.cache.clear
  end

  test "subscribes to a valid match stream" do
    subscribe(match_id: @match.id)

    assert subscription.confirmed?
    assert_has_stream_for @match
  end

  test "invalid match subscription confirms but does not stream" do
    subscribe(match_id: -1)

    assert subscription.confirmed?
    assert_empty subscription.streams
  end

  test "send_stat updates the match and broadcasts stats" do
    subscribe(match_id: @match.id)

    assert_broadcast_on(@match, { w1_stat: "T3", w2_stat: "E1" }) do
      perform :send_stat, {
        new_w1_stat: "T3",
        new_w2_stat: "E1"
      }
    end

    @match.reload
    assert_equal "T3", @match.w1_stat
    assert_equal "E1", @match.w2_stat
  end

  test "send_stat updates only w1 stat when only w1 is provided" do
    subscribe(match_id: @match.id)

    assert_broadcast_on(@match, { w1_stat: "T3", w2_stat: nil }.compact) do
      perform :send_stat, { new_w1_stat: "T3" }
    end

    @match.reload
    assert_equal "T3", @match.w1_stat
    assert_nil @match.w2_stat
  end

  test "send_stat updates only w2 stat when only w2 is provided" do
    subscribe(match_id: @match.id)

    assert_broadcast_on(@match, { w1_stat: nil, w2_stat: "E1" }.compact) do
      perform :send_stat, { new_w2_stat: "E1" }
    end

    @match.reload
    assert_nil @match.w1_stat
    assert_equal "E1", @match.w2_stat
  end

  test "send_stat with empty payload does not update or broadcast" do
    subscribe(match_id: @match.id)
    stream = MatchChannel.broadcasting_for(@match)
    ActionCable.server.pubsub.broadcasts(stream).clear

    perform :send_stat, {}

    @match.reload
    assert_nil @match.w1_stat
    assert_nil @match.w2_stat
    assert_empty ActionCable.server.pubsub.broadcasts(stream)
  end

  test "send_scoreboard caches and broadcasts scoreboard state" do
    subscribe(match_id: @match.id)
    scoreboard_state = {
      "participantScores" => { "w1" => 2, "w2" => 0 },
      "metadata" => { "boutNumber" => @match.bout_number }
    }

    assert_broadcast_on(@match, { scoreboard_state: scoreboard_state }) do
      perform :send_scoreboard, { scoreboard_state: scoreboard_state }
    end

    cached_state = Rails.cache.read("tournament:#{@match.tournament_id}:match:#{@match.id}:scoreboard_state")
    assert_equal scoreboard_state, cached_state
  end

  test "send_scoreboard with blank payload does not cache or broadcast" do
    subscribe(match_id: @match.id)
    stream = MatchChannel.broadcasting_for(@match)
    ActionCable.server.pubsub.broadcasts(stream).clear

    perform :send_scoreboard, { scoreboard_state: nil }

    assert_nil Rails.cache.read("tournament:#{@match.tournament_id}:match:#{@match.id}:scoreboard_state")
    assert_empty ActionCable.server.pubsub.broadcasts(stream)
  end

  test "request_sync transmits match data and cached scoreboard state" do
    @match.update!(
      w1_stat: "T3",
      w2_stat: "E1",
      score: "3-1",
      win_type: "Decision",
      winner_id: @match.w1,
      finished: 1
    )
    scoreboard_state = {
      "participantScores" => { "w1" => 3, "w2" => 1 },
      "metadata" => { "boutNumber" => @match.bout_number }
    }
    Rails.cache.write(
      "tournament:#{@match.tournament_id}:match:#{@match.id}:scoreboard_state",
      scoreboard_state
    )

    subscribe(match_id: @match.id)
    perform :request_sync

    assert_equal({
      "w1_stat" => "T3",
      "w2_stat" => "E1",
      "score" => "3-1",
      "win_type" => "Decision",
      "winner_name" => @match.wrestler1.name,
      "winner_id" => @match.w1,
      "finished" => 1,
      "scoreboard_state" => scoreboard_state
    }, transmissions.last)
  end

  test "request_sync transmits unfinished match data without scoreboard cache" do
    @match.update!(
      w1_stat: "T3",
      w2_stat: "E1",
      score: nil,
      win_type: nil,
      winner_id: nil,
      finished: nil
    )

    subscribe(match_id: @match.id)
    perform :request_sync

    assert_equal({
      "w1_stat" => "T3",
      "w2_stat" => "E1"
    }, transmissions.last)
  end
end
