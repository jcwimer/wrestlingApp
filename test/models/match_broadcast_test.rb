require 'test_helper'

class MatchBroadcastTest < ActiveSupport::TestCase
  include ActionView::RecordIdentifier

  test "broadcasts to old and new mats when mat changes" do
    create_double_elim_tournament_single_weight_1_6(4)
    mat1 = @tournament.mats.create!(name: "Mat 1")
    mat2 = @tournament.mats.create!(name: "Mat 2")
    @tournament.matches.update_all(mat_id: nil)
    match = @tournament.matches.first

    # Set an initial mat
    match.update!(mat: mat1)
    stream1 = stream_name_for(mat1)
    stream2 = stream_name_for(mat2)

    # Clear the stream so we can test changes from this state
    clear_streams(stream1, stream2)

    # Update the mat and check the stream
    match.update!(mat: mat2)
    assert_equal [mat1.id, mat2.id], match.saved_change_to_mat_id

    assert_equal 1, broadcasts_for(stream1).size
    assert_equal 1, broadcasts_for(stream2).size

    assert_includes broadcasts_for(stream2).last, dom_id(mat2, :current_match)
  end

  test "broadcasts when a match is removed from a mat" do
    create_double_elim_tournament_single_weight_1_6(4)
    mat = @tournament.mats.create!(name: "Mat 1")
    @tournament.matches.update_all(mat_id: nil)
    match = @tournament.matches.first

    # Set an initial mat
    match.update!(mat: mat)
    stream = stream_name_for(mat)

    # Clear the stream so we can test changes from this state
    clear_streams(stream)

    # Update the mat and check the stream
    match.update!(mat: nil)
    assert_equal [mat.id, nil], match.saved_change_to_mat_id

    assert_equal 1, broadcasts_for(stream).size
    assert_includes broadcasts_for(stream).last, dom_id(mat, :current_match)
  end

  test "destroy_all_matches clears mats and broadcasts no matches assigned" do
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
    assert_equal [nil, nil, nil, nil], mat.reload.queue_match_ids
  end

  test "wipe tournament matches service clears mats and broadcasts no matches assigned" do
    create_double_elim_tournament_single_weight_1_6(4)
    mat = @tournament.mats.create!(name: "Mat 1")
    @tournament.reset_and_fill_bout_board
    stream = stream_name_for(mat)

    clear_streams(stream)
    WipeTournamentMatches.new(@tournament).setUpMatchGeneration

    assert_operator broadcasts_for(stream).size, :>, 0
    payload = broadcasts_for(stream).last
    assert_includes payload, dom_id(mat, :current_match)
    assert_includes payload, "No matches assigned to this mat."
    assert_equal [nil, nil, nil, nil], mat.reload.queue_match_ids
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
