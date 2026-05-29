require "test_helper"

class MatScoreboardChannelTest < ActionCable::Channel::TestCase
  setup do
    @mat = mats(:one)
    @match = matches(:tournament_1_bout_1000)
    @alternate_match = matches(:tournament_1_bout_1001)
    Rails.cache.clear
    @mat.update!(queue1: @match.id, queue2: @alternate_match.id, queue3: nil, queue4: nil)
    @mat.set_selected_scoreboard_match!(@match)
    @mat.set_last_match_result!("106 lbs - Example Winner Decision Example Loser 3-1")
  end

  test "subscribes to a valid mat stream and transmits scoreboard payload" do
    subscribe(mat_id: @mat.id)

    assert subscription.confirmed?
    assert_has_stream_for @mat
    assert_equal(
      {
        "mat_id" => @mat.id,
        "queue1_bout_number" => @match.bout_number,
        "queue1_match_id" => @match.id,
        "selected_bout_number" => @match.bout_number,
        "selected_match_id" => @match.id,
        "last_match_result" => "106 lbs - Example Winner Decision Example Loser 3-1"
      },
      transmissions.last
    )
  end

  test "rejects subscription for an invalid mat" do
    subscribe(mat_id: -1)

    assert subscription.rejected?
  end

  test "allows anonymous subscription for a private tournament mat" do
    @mat.tournament.update!(is_public: false)
    stub_connection current_user: nil

    subscribe(mat_id: @mat.id)

    assert subscription.confirmed?
    assert_has_stream_for @mat
  end

  test "allows tournament owner subscription for a private tournament mat" do
    @mat.tournament.update!(is_public: false)
    stub_connection current_user: users(:one)

    subscribe(mat_id: @mat.id)

    assert subscription.confirmed?
    assert_has_stream_for @mat
  end

  test "transmits payload with queue1 and no selected match" do
    @mat.set_selected_scoreboard_match!(nil)

    subscribe(mat_id: @mat.id)

    assert_equal(
      {
        "mat_id" => @mat.id,
        "queue1_bout_number" => @match.bout_number,
        "queue1_match_id" => @match.id,
        "selected_bout_number" => nil,
        "selected_match_id" => nil,
        "last_match_result" => "106 lbs - Example Winner Decision Example Loser 3-1"
      },
      transmissions.last
    )
  end

  test "transmits payload when selected match differs from queue1" do
    @mat.set_selected_scoreboard_match!(@alternate_match)

    subscribe(mat_id: @mat.id)

    assert_equal(
      {
        "mat_id" => @mat.id,
        "queue1_bout_number" => @match.bout_number,
        "queue1_match_id" => @match.id,
        "selected_bout_number" => @alternate_match.bout_number,
        "selected_match_id" => @alternate_match.id,
        "last_match_result" => "106 lbs - Example Winner Decision Example Loser 3-1"
      },
      transmissions.last
    )
  end

  test "transmits payload when no queue1 match exists" do
    @mat.update!(queue1: nil, queue2: nil, queue3: nil, queue4: nil)
    @mat.set_selected_scoreboard_match!(nil)

    subscribe(mat_id: @mat.id)

    assert_equal(
      {
        "mat_id" => @mat.id,
        "queue1_bout_number" => nil,
        "queue1_match_id" => nil,
        "selected_bout_number" => nil,
        "selected_match_id" => nil,
        "last_match_result" => "106 lbs - Example Winner Decision Example Loser 3-1"
      },
      transmissions.last
    )
  end

  test "transmits payload with blank last match result" do
    @mat.set_last_match_result!(nil)

    subscribe(mat_id: @mat.id)

    assert_equal(
      {
        "mat_id" => @mat.id,
        "queue1_bout_number" => @match.bout_number,
        "queue1_match_id" => @match.id,
        "selected_bout_number" => @match.bout_number,
        "selected_match_id" => @match.id,
        "last_match_result" => nil
      },
      transmissions.last
    )
  end
end
