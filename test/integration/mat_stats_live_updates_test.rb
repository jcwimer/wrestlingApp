require "test_helper"

class MatStatsLiveUpdatesTest < ActionDispatch::IntegrationTest
  include ActionView::RecordIdentifier

  test "destroying all matches broadcasts no-match state for mat stats stream" do
    create_double_elim_tournament_single_weight_1_6(4)
    mat = @tournament.mats.create!(name: "Mat 1")
    @tournament.reset_and_fill_bout_board
    stream = stream_name_for(mat)

    clear_streams(stream)
    @tournament.destroy_all_matches

    assert_operator broadcasts_for(stream).size, :>, 0
    payload = broadcasts_for(stream).last
    assert_includes payload, dom_id(mat, :current_match)
    assert_includes payload, "No matches assigned to this mat."
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
end
