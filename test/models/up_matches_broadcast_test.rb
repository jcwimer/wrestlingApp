require "test_helper"

class UpMatchesBroadcastTest < ActiveSupport::TestCase
  test "tournament broadcaster emits replace action for up matches board" do
    tournament = tournaments(:one)
    stream = stream_name_for(tournament)
    clear_streams(stream)

    Tournament.broadcast_up_matches_board(tournament.id)

    assert_operator broadcasts_for(stream).size, :>, 0
    payload = broadcasts_for(stream).last
    assert_up_matches_replace_payload(payload)
  end

  test "mat queue change broadcasts up matches board update" do
    tournament = tournaments(:one)
    mat = mats(:one)
    match = matches(:tournament_1_bout_2000)
    stream = stream_name_for(tournament)
    clear_streams(stream)

    mat.update!(queue1: match.id)

    assert_operator broadcasts_for(stream).size, :>, 0
    assert_up_matches_replace_payload(broadcasts_for(stream).last)
  end

  test "mat clear_queue broadcasts up matches board update" do
    tournament = tournaments(:one)
    mat = mats(:one)
    match = matches(:tournament_1_bout_2000)
    stream = stream_name_for(tournament)

    mat.update!(queue1: match.id)
    clear_streams(stream)

    mat.clear_queue!

    assert_operator broadcasts_for(stream).size, :>, 0
    assert_up_matches_replace_payload(broadcasts_for(stream).last)
  end

  test "match mat assignment change broadcasts up matches board update" do
    tournament = tournaments(:one)
    mat = mats(:one)
    match = matches(:tournament_1_bout_2001)
    stream = stream_name_for(tournament)
    clear_streams(stream)

    match.update!(mat_id: mat.id)

    assert_operator broadcasts_for(stream).size, :>, 0
    assert_up_matches_replace_payload(broadcasts_for(stream).last)
  end

  test "match mat unassignment broadcasts up matches board update" do
    tournament = tournaments(:one)
    mat = mats(:one)
    match = matches(:tournament_1_bout_2001)
    stream = stream_name_for(tournament)

    match.update!(mat_id: mat.id)
    clear_streams(stream)

    match.update!(mat_id: nil)

    assert_operator broadcasts_for(stream).size, :>, 0
    assert_up_matches_replace_payload(broadcasts_for(stream).last)
  end

  test "mat update without queue slot changes does not broadcast up matches board update" do
    tournament = tournaments(:one)
    mat = mats(:one)
    stream = stream_name_for(tournament)
    clear_streams(stream)

    mat.update!(name: "Mat One Renamed")

    assert_equal 0, broadcasts_for(stream).size
  end

  test "match update without mat_id change does not broadcast up matches board update" do
    tournament = tournaments(:one)
    match = matches(:tournament_1_bout_2001)
    stream = stream_name_for(tournament)
    clear_streams(stream)

    match.update!(w1_stat: "Local stat change")

    assert_equal 0, broadcasts_for(stream).size
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

  def stream_name_for(streamable)
    Turbo::StreamsChannel.send(:stream_name_from, [streamable])
  end

  # Broadcast payloads may be JSON-escaped in test adapters, so assert semantic markers.
  def assert_up_matches_replace_payload(payload)
    assert_includes payload, "up_matches_board"
    assert_includes payload, "replace"
    assert_includes payload, "turbo-stream"
  end
end
