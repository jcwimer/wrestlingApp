require 'test_helper'

class ModifiedDoubleEliminationWrestlerScore < ActionDispatch::IntegrationTest
  def setup
    create_double_elim_tournament_single_weight(14, "Modified 16 Man Double Elimination 1-8")
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
    round1 = matches.select{|m| m.round == 1}.first
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
    round2 = matches.select{|m| m.round == 2 and m.bracket_position == "Conso"}.first
    quarter = matches.select{|m| m.bracket_position == "Conso Quarter"}.first
    semi = matches.select{|m| m.bracket_position == "Conso Semis"}.first
    winner_by_name_by_bye("Test1", round2)
    winner_by_name_by_bye("Test1", quarter)
    winner_by_name("Test1", semi)
    wrestler_points_calc = CalculateWrestlerTeamScore.new(get_wretler_by_name("Test1"))
    assert wrestler_points_calc.byePoints == 2
  end
end