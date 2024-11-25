require 'test_helper'

class MatAssignmentRules < ActionDispatch::IntegrationTest
  def setup
    create_double_elim_tournament_1_6_with_multiple_weights_and_multiple_mats(6, 5, 3) # 6 wrestlers, 5 weights, 3 mats
  end

  test "Mat assignment works with no mat assignment rules" do
    @tournament.reset_and_fill_bout_board
    assert @tournament.mats.first.matches.first != nil
  end

  test "Mat assignment only assigns matches for a certain weight" do
    assignment_weight_id = @tournament.weights.second.id
    mat = @tournament.mats.first

    mat_assignment_rule = MatAssignmentRule.new(
      mat_id: mat.id,
      weight_classes: [assignment_weight_id],
      tournament_id: @tournament.id
    )
    assert mat_assignment_rule.save, "Mat assignment rule should be saved successfully"

    @tournament.reload
    @tournament.reset_and_fill_bout_board

    mat.reload
    assigned_matches = mat.matches.reload

    assert_not_empty assigned_matches, "Matches should have been assigned to the mat"
    assert assigned_matches.all? { |match| match.weight_id == assignment_weight_id },
           "All matches assigned to the mat should belong to the specified weight class"
  end

  test "Mat assignment only assigns matches for round 2" do
    mat = @tournament.mats.first

    mat_assignment_rule = MatAssignmentRule.new(
      mat_id: mat.id,
      rounds: [2],
      tournament_id: @tournament.id
    )
    assert mat_assignment_rule.save, "Mat assignment rule should be saved successfully"

    @tournament.reload
    @tournament.reset_and_fill_bout_board

    mat.reload
    assigned_matches = mat.matches.reload

    assert_not_empty assigned_matches, "Matches should have been assigned to the mat"
    assert assigned_matches.all? { |match| match.round == 2 },
           "All matches assigned to the mat should only be for round 2"
  end

  test "Mat assignment only assigns matches for bracket position 1/2" do
    mat = @tournament.mats.first

    mat_assignment_rule = MatAssignmentRule.new(
      mat_id: mat.id,
      bracket_positions: ['1/2'],
      tournament_id: @tournament.id
    )
    assert mat_assignment_rule.save, "Mat assignment rule should be saved successfully"

    @tournament.reload
    @tournament.reset_and_fill_bout_board

    mat.reload
    assigned_matches = mat.matches.reload

    assert_not_empty assigned_matches, "Matches should have been assigned to the mat"
    assert assigned_matches.all? { |match| match.bracket_position == '1/2' },
           "All matches assigned to the mat should only be for bracket_position 1/2"
  end

  test "Mat assignment only assigns matches for a certain weight, round, and bracket position" do
    assignment_weight_id = @tournament.weights.first.id # Use the first weight
    mat = @tournament.mats.first
    
    last_round = @tournament.matches.maximum(:round) # Dynamically fetch the last round
    finals_bracket_position = '1/2' # Finals bracket position
    
    # Verify that there are matches in the last round with the '1/2' bracket position
    relevant_matches = @tournament.matches.where(
      weight_id: assignment_weight_id,
      round: last_round,
      bracket_position: finals_bracket_position
    )
    assert_not_empty relevant_matches, "There should be matches in the last round with the '1/2' bracket position"
    
    mat_assignment_rule = MatAssignmentRule.new(
      mat_id: mat.id,
      weight_classes: [assignment_weight_id],
      rounds: [last_round], # Use the last round dynamically
      bracket_positions: [finals_bracket_position], # Use '1/2' as the bracket position
      tournament_id: @tournament.id
    )
    assert mat_assignment_rule.save, "Mat assignment rule should be saved successfully"
    
    @tournament.reload
    @tournament.reset_and_fill_bout_board
    
    mat.reload
    assigned_matches = mat.matches.reload
    
    assert_not_empty assigned_matches, "Matches should have been assigned to the mat"
    
    assert(
      assigned_matches.all? do |match|
        match.weight_id == assignment_weight_id &&
        match.round == last_round &&
        match.bracket_position == finals_bracket_position
      end,
      "All matches assigned to the mat should satisfy all conditions (weight, round, and bracket position)"
    )
  end    

  test "No matches assigned when no matches meet rule criteria" do
    mat = @tournament.mats.first

    mat_assignment_rule = MatAssignmentRule.new(
      mat_id: mat.id,
      weight_classes: [-1], # Nonexistent weight ID
      tournament_id: @tournament.id
    )
    assert mat_assignment_rule.save, "Mat assignment rule should be saved successfully"

    @tournament.reload
    @tournament.reset_and_fill_bout_board

    mat.reload
    assigned_matches = mat.matches.reload

    assert_empty assigned_matches, "No matches should have been assigned to the mat"
  end

  test "Multiple mats follow their respective rules" do
    mat1 = @tournament.mats.first
    mat2 = @tournament.mats.second

    mat1_rule = MatAssignmentRule.new(
      mat_id: mat1.id,
      weight_classes: [@tournament.weights.first.id],
      tournament_id: @tournament.id
    )
    assert mat1_rule.save, "Mat 1 assignment rule should be saved successfully"

    mat2_rule = MatAssignmentRule.new(
      mat_id: mat2.id,
      rounds: [3],
      tournament_id: @tournament.id
    )
    assert mat2_rule.save, "Mat 2 assignment rule should be saved successfully"

    @tournament.reload
    @tournament.reset_and_fill_bout_board

    mat1.reload
    mat2.reload

    mat1_matches = mat1.matches.reload
    mat2_matches = mat2.matches.reload

    assert_not_empty mat1_matches, "Matches should have been assigned to Mat 1"
    assert_not_empty mat2_matches, "Matches should have been assigned to Mat 2"

    assert mat1_matches.all? { |match| match.weight_id == @tournament.weights.first.id },
           "All matches assigned to Mat 1 should be for the specified weight class"

    assert mat2_matches.all? { |match| match.round == 3 },
           "All matches assigned to Mat 2 should be for the specified round"
  end

  test "No matches assigned in an empty tournament" do
    # Use the tournament created in the setup
    @tournament.matches.destroy_all # Remove all matches to simulate an empty tournament
  
    mat = @tournament.mats.first
  
    mat_assignment_rule = MatAssignmentRule.new(
      mat_id: mat.id,
      rounds: [1], # Arbitrary round; no matches should exist anyway
      tournament_id: @tournament.id
    )
    assert mat_assignment_rule.save, "Mat assignment rule should be saved successfully"
  
    @tournament.reset_and_fill_bout_board
  
    mat.reload
    assigned_matches = mat.matches.reload
  
    assert_empty assigned_matches, "No matches should have been assigned for an empty tournament"
  end  
end
