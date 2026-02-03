require "test_helper"

class BoutBoardTest < ActionDispatch::IntegrationTest
  test "only assigns matches with w1 and w2" do
    create_double_elim_tournament_single_weight(16, "Regular Double Elimination 1-6")
    mat = @tournament.mats.create!(name: "Mat 1")

    @tournament.matches.update_all(mat_id: nil)
    @tournament.matches.update_all(w1: nil)

    @tournament.reset_and_fill_bout_board
    mat.reload

    assert_empty mat.queue_match_ids.compact, "No matches should be assigned when w1 is missing"

    GenerateTournamentMatches.new(@tournament).generate
    @tournament.reload
    @tournament.matches.reload

    @tournament.matches.update_all(mat_id: nil)
    @tournament.matches.update_all(w2: nil)

    @tournament.reset_and_fill_bout_board
    mat.reload

    assert_empty mat.queue_match_ids.compact, "No matches should be assigned when w2 is missing"
  end

  test "only assigns matches without a loser1_name or loser2_name of BYE" do
    create_double_elim_tournament_single_weight(16, "Regular Double Elimination 1-6")
    mat = @tournament.mats.create!(name: "Mat 1")

    @tournament.matches.update_all(mat_id: nil)
    @tournament.matches.update_all(loser1_name: "BYE")

    @tournament.reset_and_fill_bout_board
    mat.reload

    assert_empty mat.queue_match_ids.compact, "No matches should be assigned when loser1_name is BYE"

    GenerateTournamentMatches.new(@tournament).generate
    @tournament.reload
    @tournament.matches.reload

    @tournament.matches.update_all(mat_id: nil)
    @tournament.matches.update_all(loser2_name: "BYE")

    @tournament.reset_and_fill_bout_board
    mat.reload

    assert_empty mat.queue_match_ids.compact, "No matches should be assigned when loser1_name is BYE"
  end

  test "moving queue2 from mat1 to mat2 shifts queues and unassigns bumped match" do
    create_double_elim_tournament_1_6_with_multiple_weights_and_multiple_mats(16, 8, 2)
    @tournament = Tournament.find(@tournament.id)

    eligible_matches = Match.where(tournament_id: @tournament.id)
                                  .where(finished: [nil, 0])
                                  .where.not(bout_number: nil)
                                  .where.not(w1: nil)
                                  .where.not(w2: nil)
                                  .where("loser1_name != ? OR loser1_name IS NULL", "BYE")
                                  .where("loser2_name != ? OR loser2_name IS NULL", "BYE")
                                  .where(mat_id: nil)
    assert eligible_matches.count >= 8, "Expected enough eligible matches to fill two mats"

    @tournament.reload
    @tournament.matches.reload
    @tournament.reset_and_fill_bout_board
    @tournament = Tournament.find(@tournament.id)
    mat1 = @tournament.mats.order(:id).first
    mat2 = @tournament.mats.order(:id).second
    mat1.reload
    mat2.reload

    assert mat1.queue2_match, "Expected mat1 queue2 to be assigned"
    assert mat1.queue3_match, "Expected mat1 queue3 to be assigned"
    assert mat1.queue4_match, "Expected mat1 queue4 to be assigned"
    assert mat2.queue2_match, "Expected mat2 queue2 to be assigned"
    assert mat2.queue3_match, "Expected mat2 queue3 to be assigned"
    assert mat2.queue4_match, "Expected mat2 queue4 to be assigned"

    mat1_q2 = mat1.queue2_match
    mat1_q3 = mat1.queue3_match
    mat1_q4 = mat1.queue4_match

    mat2_q2 = mat2.queue2_match
    mat2_q3 = mat2.queue3_match
    mat2_q4 = mat2.queue4_match

    mat2_q4_original_match = Match.find(mat2_q4.id)

    mat2.assign_match_to_queue!(mat1_q2, 2)

    mat1.reload
    mat2.reload

    assert_equal mat1_q2.id, mat2.queue2, "Moved match should land in mat2 queue2"
    assert_equal mat2_q2.id, mat2.queue3, "Mat2 queue2 should shift to queue3"
    assert_equal mat2_q3.id, mat2.queue4, "Mat2 queue3 should shift to queue4"
    assert_nil mat2_q4.reload.mat_id, "Original mat2 queue4 match should be unassigned"

    assert_equal mat1_q3.id, mat1.queue2, "Mat1 queue3 should shift to queue2"
    assert_equal mat1_q4.id, mat1.queue3, "Mat1 queue4 should shift to queue3"
    assert mat1.queue4, "Mat1 queue4 should be refilled"
    refute_includes [mat1_q2.id, mat1_q3.id, mat1_q4.id], mat1.queue4, "Mat1 queue4 should be a new match"
    assert_equal mat1.id, Match.find(mat1.queue4).mat_id, "New mat1 queue4 match should be assigned to mat1"
    assert_nil mat2_q4_original_match.reload.mat_id, "Mat 2 queue4 match should no longer have a mat_id"
  end

  test "moving queue2 to queue4 on the same mat shifts queues" do
    create_double_elim_tournament_1_6_with_multiple_weights_and_multiple_mats(16, 8, 1)
    @tournament.reset_and_fill_bout_board

    mat1 = @tournament.mats.order(:id).first
    mat1.reload

    assert mat1.queue2_match, "Expected mat1 queue2 to be assigned"
    assert mat1.queue3_match, "Expected mat1 queue3 to be assigned"
    assert mat1.queue4_match, "Expected mat1 queue4 to be assigned"

    mat1_q2 = mat1.queue2_match
    mat1_q3 = mat1.queue3_match
    mat1_q4 = mat1.queue4_match

    mat1.assign_match_to_queue!(mat1_q2, 4)
    mat1.reload

    assert_equal mat1_q3.id, mat1.queue2, "Mat1 queue3 should shift to queue2"
    assert_equal mat1_q4.id, mat1.queue3, "Mat1 queue4 should shift to queue3"
    assert_equal mat1_q2.id, mat1.queue4, "Mat1 queue2 should move to queue4"
  end

  test "moving queue4 to queue2 on the same mat shifts queues" do
    create_double_elim_tournament_1_6_with_multiple_weights_and_multiple_mats(16, 8, 1)
    @tournament.reset_and_fill_bout_board

    mat1 = @tournament.mats.order(:id).first
    mat1.reload

    assert mat1.queue2_match, "Expected mat1 queue2 to be assigned"
    assert mat1.queue3_match, "Expected mat1 queue3 to be assigned"
    assert mat1.queue4_match, "Expected mat1 queue4 to be assigned"

    mat1_q2 = mat1.queue2_match
    mat1_q3 = mat1.queue3_match
    mat1_q4 = mat1.queue4_match

    mat1.assign_match_to_queue!(mat1_q4, 2)
    mat1.reload

    assert_equal mat1_q4.id, mat1.queue2, "Mat1 queue4 should move to queue2"
    assert_equal mat1_q2.id, mat1.queue3, "Mat1 original queue2 should move to queue3"
    assert_equal mat1_q3.id, mat1.queue4, "Mat1 original queue3 should move to queue4"
  end

  test "queues stay filled while running through an entire tournament, mat_id's are null after a match is finished, and mat_id's exist when in a queue" do
    create_double_elim_tournament_1_6_with_multiple_weights_and_multiple_mats(16, 4, 3)
    @tournament = Tournament.find(@tournament.id)
    @tournament.reset_and_fill_bout_board

    max_iterations = @tournament.matches.count + 20
    iterations = 0

    loop do
      iterations += 1
      assert_operator iterations, :<=, max_iterations, "Loop exceeded expected match count"

      assert_queue_depth_matches_available_bouts(@tournament)

      next_match = next_queued_finishable_match(@tournament)
      break unless next_match

      next_match.update!(
        winner_id: next_match.w1,
        win_type: "Decision",
        score: "1-0",
        finished: 1
      )

      assert_nil next_match.reload.mat_id, "The match should have a null mat_id after it is finished"

      @tournament.reload
    end

    remaining_finishable = finishable_match_scope(@tournament).count
    assert_equal 0, remaining_finishable, "All finishable matches should be completed"
    assert_queue_depth_matches_available_bouts(@tournament)
  end

  test "Deleting a mat mid tournament does not delete any matches" do
    create_double_elim_tournament_1_6_with_multiple_weights_and_multiple_mats(14, 1, 3)
    assert_equal 29, @tournament.matches.count, "Before deleting a mat total number of matches for a 14 man double elim 1-6 tournament should be 29"
    assert_equal 1, @tournament.matches.select{|m| m.bracket_position == "1/2"}.count, "Before deleting a mat there should be 1 match for bracket position 1/2"
    assert_equal 1, @tournament.matches.select{|m| m.bracket_position == "3/4"}.count, "Before deleting a mat there should be 1 match for bracket position 3/4"
    assert_equal 1, @tournament.matches.select{|m| m.bracket_position == "5/6"}.count, "Before deleting a mat there should be 1 match for bracket position 5/6"
    assert_equal 8, @tournament.matches.select{|m| m.bracket_position == "Bracket Round of 16"}.count, "Before deleting a mat there should be 8 matches for bracket position Bracket Round of 16"
    assert_equal 4, @tournament.matches.select{|m| m.bracket_position == "Conso Round of 8.1"}.count, "Before deleting a mat there should be 4 matches for bracket position Conso Round of 8.1"
    assert_equal 4, @tournament.matches.select{|m| m.bracket_position == "Quarter"}.count, "Before deleting a mat there should be 4 matches for bracket position Quarter"
    assert_equal 2, @tournament.matches.select{|m| m.bracket_position == "Semis"}.count, "Before deleting a mat there should be 2 matches for bracket position Semis"
    assert_equal 4, @tournament.matches.select{|m| m.bracket_position == "Conso Round of 8.2"}.count, "Before deleting a mat there should be 4 matches for bracket position Conso Round of 8.2"
    assert_equal 2, @tournament.matches.select{|m| m.bracket_position == "Conso Quarter"}.count, "Before deleting a mat there should be 2 matches for bracket position Conso Quarter"
    assert_equal 2, @tournament.matches.select{|m| m.bracket_position == "Conso Semis"}.count, "Before deleting a mat there should be 2 matches for bracket position Conso Semis"

    @tournament.mats.first.destroy
    @tournament.reload
    @tournament.matches.reload

    assert_equal 29, @tournament.matches.count, "After deleting a mat total number of matches for a 14 man double elim 1-6 tournament should still be 29"
    assert_equal 1, @tournament.matches.select{|m| m.bracket_position == "1/2"}.count, "After deleting a mat there should still be 1 match for bracket position 1/2"
    assert_equal 1, @tournament.matches.select{|m| m.bracket_position == "3/4"}.count, "After deleting a mat there should still be 1 match for bracket position 3/4"
    assert_equal 1, @tournament.matches.select{|m| m.bracket_position == "5/6"}.count, "After deleting a mat there should still be 1 match for bracket position 5/6"
    assert_equal 8, @tournament.matches.select{|m| m.bracket_position == "Bracket Round of 16"}.count, "After deleting a mat there should still be 8 matches for bracket position Bracket Round of 16"
    assert_equal 4, @tournament.matches.select{|m| m.bracket_position == "Conso Round of 8.1"}.count, "After deleting a mat there should still be 4 matches for bracket position Conso Round of 8.1"
    assert_equal 4, @tournament.matches.select{|m| m.bracket_position == "Quarter"}.count, "After deleting a mat there should still be 4 matches for bracket position Quarter"
    assert_equal 2, @tournament.matches.select{|m| m.bracket_position == "Semis"}.count, "After deleting a mat there should still be 2 matches for bracket position Semis"
    assert_equal 4, @tournament.matches.select{|m| m.bracket_position == "Conso Round of 8.2"}.count, "After deleting a mat there should still be 4 matches for bracket position Conso Round of 8.2"
    assert_equal 2, @tournament.matches.select{|m| m.bracket_position == "Conso Quarter"}.count, "After deleting a mat there should still be 2 matches for bracket position Conso Quarter"
    assert_equal 2, @tournament.matches.select{|m| m.bracket_position == "Conso Semis"}.count, "After deleting a mat there should still be 2 matches for bracket position Conso Semis"
  end

  test "When matches are generated, they're assigned a mat in round robin fashion" do
    create_double_elim_tournament_1_6_with_multiple_weights_and_multiple_mats(16, 8, 2)
    @tournament = Tournament.find(@tournament.id)

    @tournament.reload
    @tournament.matches.reload
    @tournament.reset_and_fill_bout_board
    @tournament = Tournament.find(@tournament.id)
    mat1 = @tournament.mats.order(:id).first
    mat2 = @tournament.mats.order(:id).second
    mat1.reload
    mat2.reload
    matches_ordered_by_bout = @tournament.matches.sort_by{|m| m.bout_number}

    assert_equal matches_ordered_by_bout.first.bout_number, mat1.queue1_match.bout_number, "The first bout number of the tournament should be queue1 on mat 1"
    assert_equal matches_ordered_by_bout.second.bout_number, mat2.queue1_match.bout_number, "The second bout number of the tournament should be queue1 on mat 2"
  end

  private

  def finishable_match_scope(tournament)
    Match.where(tournament_id: tournament.id, finished: [nil, 0])
         .where.not(w1: nil)
         .where.not(w2: nil)
         .where("loser1_name != ? OR loser1_name IS NULL", "BYE")
         .where("loser2_name != ? OR loser2_name IS NULL", "BYE")
  end

  def next_queued_finishable_match(tournament)
    tournament.mats.order(:id).each do |mat|
      match = mat.queue1_match
      next unless match
      next unless match.finished != 1
      return match if match.w1.present? && match.w2.present?
    end
    nil
  end

  def assert_queue_depth_matches_available_bouts(tournament)
    available_count = finishable_match_scope(tournament).count
    queue_capacity = tournament.mats.count * 4
    expected_queued_count = [available_count, queue_capacity].min

    queued_ids = tournament.mats.order(:id).flat_map(&:queue_match_ids).compact
    assert_equal expected_queued_count, queued_ids.count,
                 "Queue depth should match available matches (expected #{expected_queued_count}, got #{queued_ids.count})"

    tournament.mats.order(:id).each do |mat|
      assert_queue_has_no_gaps(mat)
    end
  end

  def assert_queue_has_no_gaps(mat)
    if mat.queue2.present?
      assert mat.queue1.present?, "Mat #{mat.id} queue1 must be present when queue2 is present"
      assert_equal mat.id, mat.queue1_match.mat_id, "The match in queue1 should have a mat_id"
    end
    if mat.queue3.present?
      assert mat.queue2.present?, "Mat #{mat.id} queue2 must be present when queue3 is present"
      assert_equal mat.id, mat.queue2_match.mat_id, "The match in queue2 should have a mat_id"
    end
    if mat.queue4.present?
      assert mat.queue3.present?, "Mat #{mat.id} queue3 must be present when queue4 is present"
      assert_equal mat.id, mat.queue3_match.mat_id, "The match in queue3 should have a mat_id"
    end
  end
end
