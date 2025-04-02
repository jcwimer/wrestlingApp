require 'test_helper'

class DoubleEliminationWrestlerScore < ActionDispatch::IntegrationTest
  def setup
    create_double_elim_tournament_single_weight(14, "Regular Double Elimination 1-8")
  end
  
  def winner_by_name(winner_name,match)
    wrestler = @tournament.weights.first.wrestlers.select{|w| w.name == winner_name}.first
    match.w1 = wrestler.id
    match.winner_id = wrestler.id
    match.finished = 1
    match.win_type = "Decision"
    match.score = "0-0"
    match.save
  end
  
  def winner_by_name_by_bye(winner_name,match)
    wrestler = @tournament.weights.first.wrestlers.select{|w| w.name == winner_name}.first
    match.w1 = wrestler.id
    match.winner_id = wrestler.id
    match.finished = 1
    match.win_type = "BYE"
    match.score = ""
    match.save
  end
  
  def get_wretler_by_name(name)
    wrestler = @tournament.weights.first.wrestlers.select{|w| w.name == name}.first
    return wrestler
  end

  test "Wrestlers get points for byes in the championship rounds" do
    matches = @tournament.matches.reload
    round1 = matches.select{|m| m.bracket_position == "Bracket Round of 16"}.first
    quarter = matches.select{|m| m.bracket_position == "Quarter"}.first
    semi = matches.select{|m| m.bracket_position == "Semis"}.first
    winner_by_name_by_bye("Test1", round1)
    winner_by_name_by_bye("Test1", quarter)
    winner_by_name("Test1", semi)
    wrestler_points_calc = CalculateWrestlerTeamScore.new(get_wretler_by_name("Test1"))
    assert wrestler_points_calc.byePoints == 4
  end
  
  test "Wrestlers get points for byes in the consolation rounds" do
    matches = @tournament.matches.reload
    conso_r8_1 = matches.select{|m| m.bracket_position == "Conso Round of 8.1"}.first
    quarter = matches.select{|m| m.bracket_position == "Conso Quarter"}.first
    semi = matches.select{|m| m.bracket_position == "Conso Semis"}.first
    winner_by_name_by_bye("Test1", conso_r8_1)
    winner_by_name_by_bye("Test1", quarter)
    winner_by_name("Test1", semi)
    wrestler_points_calc = CalculateWrestlerTeamScore.new(get_wretler_by_name("Test1"))
    assert wrestler_points_calc.byePoints == 2
  end
  
  test "Wrestlers do not get bye points if they get byes to 1st/2nd and win by bye" do
    matches = @tournament.matches.reload
    round1 = matches.select{|m| m.bracket_position == "Bracket Round of 16"}.first
    quarter = matches.select{|m| m.bracket_position == "Quarter"}.first
    semi = matches.select{|m| m.bracket_position == "Semis"}.first
    final = matches.select{|m| m.bracket_position == "1/2"}.first
    winner_by_name_by_bye("Test1", round1)
    winner_by_name_by_bye("Test1", quarter)
    winner_by_name_by_bye("Test1", semi)
    winner_by_name_by_bye("Test1", final)
    wrestler_points_calc = CalculateWrestlerTeamScore.new(get_wretler_by_name("Test1"))
    assert wrestler_points_calc.byePoints == 0
  end
  
  test "Wrestlers do not get bye points if they get byes to 3rd/4th and win by bye" do
    matches = @tournament.matches.reload
    conso_r8_1 = matches.select{|m| m.bracket_position == "Conso Round of 8.1"}.first
    quarter = matches.select{|m| m.bracket_position == "Conso Quarter"}.first
    semi = matches.select{|m| m.bracket_position == "Conso Semis"}.first
    final = matches.select{|m| m.bracket_position == "3/4"}.first
    winner_by_name_by_bye("Test1", conso_r8_1)
    winner_by_name_by_bye("Test1", quarter)
    winner_by_name_by_bye("Test1", semi)
    winner_by_name_by_bye("Test1", final)
    wrestler_points_calc = CalculateWrestlerTeamScore.new(get_wretler_by_name("Test1"))
    assert wrestler_points_calc.byePoints == 0
  end
  
  test "Wrestlers do not get bye points if they get byes to 1st/2nd and win by decision" do
    matches = @tournament.matches.reload
    round1 = matches.select{|m| m.bracket_position == "Bracket Round of 16"}.first
    quarter = matches.select{|m| m.bracket_position == "Quarter"}.first
    semi = matches.select{|m| m.bracket_position == "Semis"}.first
    final = matches.select{|m| m.bracket_position == "1/2"}.first
    winner_by_name_by_bye("Test1", round1)
    winner_by_name_by_bye("Test1", quarter)
    winner_by_name_by_bye("Test1", semi)
    winner_by_name("Test1", final)
    wrestler_points_calc = CalculateWrestlerTeamScore.new(get_wretler_by_name("Test1"))
    assert wrestler_points_calc.byePoints == 6
  end
  
  test "Wrestlers do not get bye points if they get byes to 3rd/4th and win by decision" do
    matches = @tournament.matches.reload
    conso_r8_1 = matches.select{|m| m.bracket_position == "Conso Round of 8.1"}.first
    quarter = matches.select{|m| m.bracket_position == "Conso Quarter"}.first
    semi = matches.select{|m| m.bracket_position == "Conso Semis"}.first
    final = matches.select{|m| m.bracket_position == "3/4"}.first
    winner_by_name_by_bye("Test1", conso_r8_1)
    winner_by_name_by_bye("Test1", quarter)
    winner_by_name_by_bye("Test1", semi)
    winner_by_name("Test1", final)
    wrestler_points_calc = CalculateWrestlerTeamScore.new(get_wretler_by_name("Test1"))
    assert wrestler_points_calc.byePoints == 3
  end
end