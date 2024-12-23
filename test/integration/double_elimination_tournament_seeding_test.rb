require 'test_helper'

class EightManDoubleEliminationSixPlacesRunThrough < ActionDispatch::IntegrationTest
  def setup
    create_double_elim_tournament_single_weight(8, "Regular Double Elimination 1-8")
    @tournament.wrestlers.each do | wrestler |
      if wrestler.original_seed > 4
        wrestler.original_seed = nil
        wrestler.bracket_line = nil
        wrestler.save
      end
      GenerateTournamentMatches.new(@tournament.reload).generate
    end
  end

  test "Wrestlers with seeds should go on certain lines and it should be random for everyone else" do
    matches = @tournament.reload.matches

    matches.select{|m| m.round == 1}.each do | match |
      assert(match.wrestler1.original_seed != nil)
      assert(match.wrestler2.original_seed == nil)
    end
  end

  test "Regenerating matches without changes should keep lines the same" do
    wrestlers = @tournament.wrestlers
    test_one_bracket_line_original = wrestlers.select{|w|w.name == "Test1"}.first.bracket_line
    test_two_bracket_line_original = wrestlers.select{|w|w.name == "Test2"}.first.bracket_line
    test_three_bracket_line_original = wrestlers.select{|w|w.name == "Test3"}.first.bracket_line
    test_four_bracket_line_original = wrestlers.select{|w|w.name == "Test4"}.first.bracket_line
    test_five_bracket_line_original = wrestlers.select{|w|w.name == "Test5"}.first.bracket_line
    test_six_bracket_line_original = wrestlers.select{|w|w.name == "Test6"}.first.bracket_line
    test_seven_bracket_line_original = wrestlers.select{|w|w.name == "Test7"}.first.bracket_line
    test_eight_bracket_line_original = wrestlers.select{|w|w.name == "Test8"}.first.bracket_line

    GenerateTournamentMatches.new(@tournament.reload).generate

    wrestlers = @tournament.reload.wrestlers
    test_one_bracket_line_second = wrestlers.select{|w|w.name == "Test1"}.first.bracket_line
    test_two_bracket_line_second = wrestlers.select{|w|w.name == "Test2"}.first.bracket_line
    test_three_bracket_line_second = wrestlers.select{|w|w.name == "Test3"}.first.bracket_line
    test_four_bracket_line_second = wrestlers.select{|w|w.name == "Test4"}.first.bracket_line
    test_five_bracket_line_second = wrestlers.select{|w|w.name == "Test5"}.first.bracket_line
    test_six_bracket_line_second = wrestlers.select{|w|w.name == "Test6"}.first.bracket_line
    test_seven_bracket_line_second = wrestlers.select{|w|w.name == "Test7"}.first.bracket_line
    test_eight_bracket_line_second = wrestlers.select{|w|w.name == "Test8"}.first.bracket_line

    assert(test_one_bracket_line_original == test_one_bracket_line_second)
    assert(test_two_bracket_line_original == test_two_bracket_line_second)
    assert(test_three_bracket_line_original == test_three_bracket_line_second)
    assert(test_four_bracket_line_original == test_four_bracket_line_second)
    assert(test_five_bracket_line_original == test_five_bracket_line_second)
    assert(test_six_bracket_line_original == test_six_bracket_line_second)
    assert(test_seven_bracket_line_original == test_seven_bracket_line_second)
    assert(test_eight_bracket_line_original == test_eight_bracket_line_second)
  end

  test "Deleting a wrestler and generating produces a BYE for the person who lost their opponent" do
    wrestler_three_first_round = @tournament.reload.matches.select{|m| m.round == 1 && m.wrestler1.name == "Test3"}.first
    wrestler_three_first_round.wrestler2.destroy
    GenerateTournamentMatches.new(@tournament.reload).generate
    matches = @tournament.reload.matches

    match_with_bye = matches.select{|m|m.loser2_name == "BYE"}.first
    assert(match_with_bye.wrestler1.name == "Test3")
  end

  test "Deleting a seeded wrestler reseeding and generating produces a BYE for the non seeded opponent who lost their match" do
    wrestler_two_first_round = @tournament.reload.matches.select{|m| m.round == 1 && m.wrestler1.name == "Test2"}.first
    wrestler_four_first_round = @tournament.matches.select{|m| m.round == 1 && m.wrestler1.name == "Test4"}.first
    wrestler_four_first_round_opponent = wrestler_four_first_round.wrestler2.id
    wrestler_two_first_round.wrestler1.destroy

    wrestlers = @tournament.wrestlers
    wrestler_three = wrestlers.select{|w| w.name == "Test3"}.first
    wrestler_three.original_seed = 2
    wrestler_three.save
    wrestler_four = wrestlers.select{|w| w.name == "Test4"}.first
    wrestler_four.original_seed = 3
    wrestler_four.save
    GenerateTournamentMatches.new(@tournament.reload).generate
    matches = @tournament.reload.matches

    assert(matches.select{|m| m.round == 1 && m.w2 == wrestler_four_first_round_opponent}.first.loser1_name == "BYE")
  end

  test "Swapping seeds should change just the bracket line of the two wrestlers swapped" do
    wrestlers = @tournament.wrestlers
    test_one_bracket_line_original = wrestlers.select{|w|w.name == "Test1"}.first.bracket_line
    test_two_bracket_line_original = wrestlers.select{|w|w.name == "Test2"}.first.bracket_line
    test_three_bracket_line_original = wrestlers.select{|w|w.name == "Test3"}.first.bracket_line
    test_four_bracket_line_original = wrestlers.select{|w|w.name == "Test4"}.first.bracket_line
    test_five_bracket_line_original = wrestlers.select{|w|w.name == "Test5"}.first.bracket_line
    test_six_bracket_line_original = wrestlers.select{|w|w.name == "Test6"}.first.bracket_line
    test_seven_bracket_line_original = wrestlers.select{|w|w.name == "Test7"}.first.bracket_line
    test_eight_bracket_line_original = wrestlers.select{|w|w.name == "Test8"}.first.bracket_line

    wrestler_three = wrestlers.select{|w| w.name == "Test3"}.first
    wrestler_three.original_seed = 4
    wrestler_three.save
    wrestler_four = wrestlers.select{|w| w.name == "Test4"}.first
    wrestler_four.original_seed = 3
    wrestler_four.save

    GenerateTournamentMatches.new(@tournament.reload).generate

    wrestlers = @tournament.reload.wrestlers
    test_one_bracket_line_second = wrestlers.select{|w|w.name == "Test1"}.first.bracket_line
    test_two_bracket_line_second = wrestlers.select{|w|w.name == "Test2"}.first.bracket_line
    test_three_bracket_line_second = wrestlers.select{|w|w.name == "Test3"}.first.bracket_line
    test_four_bracket_line_second = wrestlers.select{|w|w.name == "Test4"}.first.bracket_line
    test_five_bracket_line_second = wrestlers.select{|w|w.name == "Test5"}.first.bracket_line
    test_six_bracket_line_second = wrestlers.select{|w|w.name == "Test6"}.first.bracket_line
    test_seven_bracket_line_second = wrestlers.select{|w|w.name == "Test7"}.first.bracket_line
    test_eight_bracket_line_second = wrestlers.select{|w|w.name == "Test8"}.first.bracket_line

    # Other people not swapped
    assert(test_one_bracket_line_original == test_one_bracket_line_second)
    assert(test_two_bracket_line_original == test_two_bracket_line_second)
    assert(test_five_bracket_line_original == test_five_bracket_line_second)
    assert(test_six_bracket_line_original == test_six_bracket_line_second)
    assert(test_seven_bracket_line_original == test_seven_bracket_line_second)
    assert(test_eight_bracket_line_original == test_eight_bracket_line_second)
    # Two people swapped
    assert(test_three_bracket_line_original == test_four_bracket_line_second)
    assert(test_four_bracket_line_original == test_three_bracket_line_second)
  end

  test "Changing a wrestler from not seeded to seeded should only change his line and the person who had the line they now get" do
    matches_original = @tournament.matches.select{|m| m.round == 1}
    original_wrestler4_opponent_name = matches_original.select{|m| m.wrestler1.name == "Test4"}.first.wrestler2.name
 
    wrestler_seven = @tournament.wrestlers.select{|w| w.name == "Test7"}.first
    wrestler_seven.original_seed = 5
    wrestler_seven.save

    GenerateTournamentMatches.new(@tournament.reload).generate

    matches_second = @tournament.reload.matches.select{|m| m.round == 1}
    # everyone else should have the same opponent
    matches_original.each do |match|
      match_wrestler1_name = @tournament.wrestlers.select{|w| w.id == match.w1}.first.name
      match_wrestler2_name = @tournament.wrestlers.select{|w| w.id == match.w2}.first.name
      matching_second_match = matches_second.select{|m| m.bracket_position_number == match.bracket_position_number}.first
      match_second_wrestler1_name = @tournament.wrestlers.select{|w| w.id == matching_second_match.w1}.first.name
      match_second_wrestler2_name = @tournament.wrestlers.select{|w| w.id == matching_second_match.w2}.first.name
      # Test4 should now wrestle Test7 since Test7 is now 5th seed
      if match_wrestler1_name == "Test4"
        assert match_second_wrestler2_name == "Test7"
      # Test4's original opponenet should now wrestle Test7's original opponent
      elsif match_wrestler2_name == "Test7"
        assert match_second_wrestler2_name == original_wrestler4_opponent_name
      # Everyone else should have their original opponent
      else
        assert match_wrestler2_name == match_second_wrestler2_name
      end
    end
  end

end