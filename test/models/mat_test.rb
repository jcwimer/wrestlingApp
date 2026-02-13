require 'test_helper'

class MatTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  
  test "Mat validations" do
    mat = Mat.new
    assert_not mat.valid?
    assert_equal [:tournament, :name], mat.errors.attribute_names
  end

  test "queue_matches refreshes after queue slots change and record reloads" do
    create_double_elim_tournament_1_6_with_multiple_weights_and_multiple_mats(16, 4, 1)
    @tournament.reset_and_fill_bout_board

    mat = @tournament.mats.first
    initial_queue_ids = mat.queue_matches.map { |match| match&.id }
    assert initial_queue_ids.compact.any?, "Expected initial queue to contain matches"

    Mat.where(id: mat.id).update_all(queue1: nil, queue2: nil, queue3: nil, queue4: nil)
    mat.reload

    refreshed_queue_ids = mat.queue_matches.map { |match| match&.id }
    assert_equal [nil, nil, nil, nil], refreshed_queue_ids, "Expected queue_matches to refresh after reload and slot changes"
  end
  
end
