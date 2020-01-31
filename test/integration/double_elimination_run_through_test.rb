require 'test_helper'

class DoubleEliminationRunThrough < ActionDispatch::IntegrationTest
  def setup
  end

  def winner_by_name(winner_name,match)
    wrestler = @tournament.weights.first.wrestlers.select{|w| w.name == winner_name}.first
    match.winner_id = wrestler.id
    match.finished = 1
    match.win_type = "Decision"
    match.score = "0-0"
    match.save
  end

  test "8 man double elimination" do
    create_double_elim_tournament_single_weight_1_6(6)
    matches = @tournament.matches.reload

    round1 = matches.select{|m| m.round == 1}
    winner_by_name("Test4", round1.select{|m| m.bracket_position_number == 2}.first)
    winner_by_name("Test3", round1.select{|m| m.bracket_position_number == 3}.first)

    semis = matches.select{|m| m.bracket_position == "Semis"}.sort_by{|m| m.bracket_position_number}
    assert semis.first.reload.wrestler1.name == "Test1"
    assert semis.first.reload.wrestler2.name == "Test4"
    assert semis.second.reload.wrestler1.name == "Test3"
    assert semis.second.reload.wrestler2.name == "Test2"
    winner_by_name("Test4",semis.first)
    winner_by_name("Test2",semis.second)

    conso_quarter = matches.select{|m| m.bracket_position == "Conso Quarter"}.sort_by{|m| m.bracket_position_number}
    assert conso_quarter.first.reload.loser1_name == "BYE"
    assert conso_quarter.first.reload.wrestler2.name == "Test6"
    assert conso_quarter.second.reload.wrestler1.name == "Test5"
    assert conso_quarter.second.reload.loser2_name == "BYE"

    conso_semis = matches.select{|m| m.bracket_position == "Conso Semis"}.sort_by{|m| m.bracket_position_number}
    assert conso_semis.first.reload.wrestler1.name == "Test1"
    assert conso_semis.first.reload.wrestler2.name == "Test6"
    assert conso_semis.second.reload.wrestler1.name == "Test3"
    assert conso_semis.second.reload.wrestler2.name == "Test5"
    winner_by_name("Test1",conso_semis.first)
    winner_by_name("Test5",conso_semis.second)

    first_finals = matches.select{|m| m.bracket_position == "1/2"}.first
    third_finals = matches.select{|m| m.bracket_position == "3/4"}.first
    fifth_finals = matches.select{|m| m.bracket_position == "5/6"}.first

    assert first_finals.reload.wrestler1.name == "Test4"
    assert first_finals.reload.wrestler2.name == "Test2"

    assert third_finals.reload.wrestler1.name == "Test1"
    assert third_finals.reload.wrestler2.name == "Test5"

    assert fifth_finals.reload.wrestler1.name == "Test6"
    assert fifth_finals.reload.wrestler2.name == "Test3"

    # DEBUG
    # matches.sort_by{|m| m.bout_number}.each do |match|
    #   match.reload
    #   puts "Round #{match.round} #{match.w1_bracket_name} vs #{match.w2_bracket_name}"
    # end
  end


end