require 'test_helper'

class ModifiedDoubleEliminationSixPlacesRunThrough < ActionDispatch::IntegrationTest
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

  test "16 man modified double elimination placing 1-6" do
    @tournament = create_double_elim_tournament_single_weight(14, "Modified 16 Man Double Elimination 1-6")
    matches = @tournament.matches.reload

    round1 = matches.select{|m| m.bracket_position == "Bracket Round of 16"}
    winner_by_name("Test9", round1.select{|m| m.bracket_position_number == 2}.first)
    winner_by_name("Test5", round1.select{|m| m.bracket_position_number == 3}.first)
    winner_by_name("Test4", round1.select{|m| m.bracket_position_number == 4}.first)
    winner_by_name("Test13", round1.select{|m| m.bracket_position_number == 5}.first)
    winner_by_name("Test6", round1.select{|m| m.bracket_position_number == 6}.first)
    winner_by_name("Test10", round1.select{|m| m.bracket_position_number == 7}.first)

    quarter = matches.select{|m| m.bracket_position == "Quarter"}.sort_by{|m| m.bracket_position_number}
    assert quarter.first.reload.wrestler1.name == "Test1"
    assert quarter.first.reload.wrestler2.name == "Test9"
    assert quarter.second.reload.wrestler1.name == "Test5"
    assert quarter.second.reload.wrestler2.name == "Test4"
    assert quarter.third.reload.wrestler1.name == "Test13"
    assert quarter.third.reload.wrestler2.name == "Test6"
    assert quarter.fourth.reload.wrestler1.name == "Test10"
    assert quarter.fourth.reload.wrestler2.name == "Test2"

    conso_round2 = matches.select{|m| m.bracket_position == "Conso Round of 8"}.sort_by{|m| m.bracket_position_number}
    assert conso_round2.first.reload.wrestler2.name == "Test8"
    assert conso_round2.second.reload.wrestler1.name == "Test12"
    assert conso_round2.second.reload.wrestler2.name == "Test14"
    assert conso_round2.third.reload.wrestler1.name == "Test3"
    assert conso_round2.third.reload.wrestler2.name == "Test11"
    assert conso_round2.fourth.reload.wrestler1.name == "Test7"

    winner_by_name("Test1", quarter.first)
    winner_by_name("Test5", quarter.second)
    winner_by_name("Test13", quarter.third)
    winner_by_name("Test10", quarter.fourth)
    winner_by_name("Test12", conso_round2.second)
    winner_by_name("Test3", conso_round2.third)

    semis = matches.select{|m| m.bracket_position == "Semis"}.sort_by{|m| m.bracket_position_number}
    assert semis.first.reload.wrestler1.name == "Test1"
    assert semis.first.reload.wrestler2.name == "Test5"
    assert semis.second.reload.wrestler1.name == "Test13"
    assert semis.second.reload.wrestler2.name == "Test10"

    conso_quarter = matches.select{|m| m.bracket_position == "Conso Quarter"}.sort_by{|m| m.bracket_position_number}
    assert conso_quarter.first.reload.wrestler1.name == "Test2"
    assert conso_quarter.first.reload.wrestler2.name == "Test8"
    assert conso_quarter.second.reload.wrestler1.name == "Test6"
    assert conso_quarter.second.reload.wrestler2.name == "Test12"
    assert conso_quarter.third.reload.wrestler1.name == "Test4"
    assert conso_quarter.third.reload.wrestler2.name == "Test3"
    assert conso_quarter.fourth.reload.wrestler1.name == "Test9"
    assert conso_quarter.fourth.reload.wrestler2.name == "Test7"

    winner_by_name("Test5",semis.first)
    winner_by_name("Test10",semis.second)
    winner_by_name("Test2", conso_quarter.first)
    winner_by_name("Test12", conso_quarter.second)
    winner_by_name("Test4", conso_quarter.third)
    winner_by_name("Test7", conso_quarter.fourth)

    conso_semis = matches.select{|m| m.bracket_position == "Conso Semis"}.sort_by{|m| m.bracket_position_number}
    assert conso_semis.first.reload.wrestler1.name == "Test2"
    assert conso_semis.first.reload.wrestler2.name == "Test12"
    assert conso_semis.second.reload.wrestler1.name == "Test4"
    assert conso_semis.second.reload.wrestler2.name == "Test7"

    winner_by_name("Test2",conso_semis.first)
    winner_by_name("Test4",conso_semis.second)

    first_finals = matches.select{|m| m.bracket_position == "1/2"}.first
    third_finals = matches.select{|m| m.bracket_position == "3/4"}.first
    fifth_finals = matches.select{|m| m.bracket_position == "5/6"}.first

    assert first_finals.reload.wrestler1.name == "Test5"
    assert first_finals.reload.wrestler2.name == "Test10"

    assert third_finals.reload.wrestler1.name == "Test1"
    assert third_finals.reload.wrestler2.name == "Test13"

    assert fifth_finals.reload.wrestler1.name == "Test2"
    assert fifth_finals.reload.wrestler2.name == "Test4"

    # DEBUG
    # matches.sort_by{|m| m.bout_number}.each do |match|
    #   match.reload
    #   puts "Round #{match.round} #{match.w1_bracket_name} vs #{match.w2_bracket_name}"
    # end
  end
end