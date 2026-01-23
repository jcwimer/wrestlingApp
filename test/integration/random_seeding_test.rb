require 'test_helper'

class RandomSeedingTest < ActionDispatch::IntegrationTest
  def setup

  end

  def clean_up_original_seeds(tournament)
    tournament.wrestlers.each do |wrestler|
        wrestler.original_seed = nil
        wrestler.save
    end
    tournament.wrestlers.reload.each do |wrestler|
      wrestler.bracket_line = nil
      wrestler.save
    end
    GenerateTournamentMatches.new(tournament).generate
  end

  test "There are no double byes in a double elimination tournament round 1" do
    create_double_elim_tournament_single_weight(18, "Regular Double Elimination 1-8")
    clean_up_original_seeds(@tournament)
    round_one_matches = @tournament.matches.reload.select{|m| m.round == 1}
    assert round_one_matches.select{|m| m.w1.nil? and m.w2.nil? }.size == 0 
  end

  test "There are the same number of matches in the top half and bottom half of a double elimination tournament in round 1" do
    create_double_elim_tournament_single_weight(18, "Regular Double Elimination 1-8")
    clean_up_original_seeds(@tournament)
    round_one_matches = @tournament.matches.reload.select{|m| m.round == 1}
    # 32 man bracket there are 16 matches so top half is bracket_position_number 1-8 and bottom is 9-16
    round_one_top_half = round_one_matches.select{|m| !m.w1.nil? and !m.w2.nil? and m.bracket_position_number < 9}
    round_one_bottom_half = round_one_matches.select{|m| !m.w1.nil? and !m.w2.nil? and m.bracket_position_number > 8}
    assert round_one_top_half.size == round_one_bottom_half.size
  end

  test "There are the same number of matches in the top half and bottom half of a double elimination tournament in round 1 in a 6 man bracket" do
    create_double_elim_tournament_single_weight(6, "Regular Double Elimination 1-8")
    clean_up_original_seeds(@tournament)
    round_one_matches = @tournament.matches.reload.select{|m| m.round == 1}
    # 8 man bracket there are 4 matches so top half is bracket_position_number 1-2 and bottom is 3-4
    round_one_top_half = round_one_matches.select{|m| !m.w1.nil? and !m.w2.nil? and m.bracket_position_number < 3}
    round_one_bottom_half = round_one_matches.select{|m| !m.w1.nil? and !m.w2.nil? and m.bracket_position_number > 2}
    assert round_one_top_half.size == round_one_bottom_half.size
  end

  test "There are no double byes in a double elimination tournament in a 6 man bracket" do
    create_double_elim_tournament_single_weight(6, "Regular Double Elimination 1-8")
    clean_up_original_seeds(@tournament)
    round_one_matches = @tournament.matches.reload.select{|m| m.round == 1}
    conso_round_one_matches = @tournament.matches.reload.select{|m| m.bracket_position == "Conso Quarter"}
    assert round_one_matches.select{|m| m.w1.nil? and m.w2.nil? }.size == 0 
    assert conso_round_one_matches.select{|m| m.loser1_name == "BYE" and m.loser2_name == "BYE" }.size == 0
  end
end