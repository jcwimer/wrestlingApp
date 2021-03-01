require 'test_helper'

class DoubleEliminationSixPlacesRunThrough < ActionDispatch::IntegrationTest
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
    assert conso_quarter.first.reload.wrestler2.name == "Test5"
    assert conso_quarter.second.reload.wrestler1.name == "Test6"
    assert conso_quarter.second.reload.loser2_name == "BYE"

    conso_semis = matches.select{|m| m.bracket_position == "Conso Semis"}.sort_by{|m| m.bracket_position_number}
    assert conso_semis.first.reload.wrestler1.name == "Test3"
    assert conso_semis.first.reload.wrestler2.name == "Test5"
    assert conso_semis.second.reload.wrestler1.name == "Test1"
    assert conso_semis.second.reload.wrestler2.name == "Test6"
    winner_by_name("Test5",conso_semis.first)
    winner_by_name("Test1",conso_semis.second)

    first_finals = matches.select{|m| m.bracket_position == "1/2"}.first
    third_finals = matches.select{|m| m.bracket_position == "3/4"}.first
    fifth_finals = matches.select{|m| m.bracket_position == "5/6"}.first

    assert first_finals.reload.wrestler1.name == "Test4"
    assert first_finals.reload.wrestler2.name == "Test2"

    assert third_finals.reload.wrestler1.name == "Test5"
    assert third_finals.reload.wrestler2.name == "Test1"

    assert fifth_finals.reload.wrestler1.name == "Test3"
    assert fifth_finals.reload.wrestler2.name == "Test6"

    # DEBUG
    # matches.sort_by{|m| m.bout_number}.each do |match|
    #   match.reload
    #   puts "Round #{match.round} #{match.w1_bracket_name} vs #{match.w2_bracket_name}"
    # end
  end

  test "16 man double elimination" do
    create_double_elim_tournament_single_weight_1_6(14)
    matches = @tournament.matches.reload

    round1 = matches.select{|m| m.round == 1}
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

    conso_round2 = matches.select{|m| m.bracket_position == "Conso" and m.round == 2}.sort_by{|m| m.bracket_position_number}
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

    conso_round3 = matches.select{|m| m.bracket_position == "Conso" and m.round == 3}.sort_by{|m| m.bracket_position_number}
    assert conso_round3.first.reload.wrestler1.name == "Test2"
    assert conso_round3.first.reload.wrestler2.name == "Test8"
    assert conso_round3.second.reload.wrestler1.name == "Test6"
    assert conso_round3.second.reload.wrestler2.name == "Test12"
    assert conso_round3.third.reload.wrestler1.name == "Test4"
    assert conso_round3.third.reload.wrestler2.name == "Test3"
    assert conso_round3.fourth.reload.wrestler1.name == "Test9"
    assert conso_round3.fourth.reload.wrestler2.name == "Test7"

    winner_by_name("Test2", conso_round3.first)
    winner_by_name("Test6", conso_round3.second)
    winner_by_name("Test3", conso_round3.third)
    winner_by_name("Test9", conso_round3.fourth)

    conso_quarter = matches.select{|m| m.bracket_position == "Conso Quarter"}.sort_by{|m| m.bracket_position_number}
    assert conso_quarter.first.reload.wrestler1.name == "Test2"
    assert conso_quarter.first.reload.wrestler2.name == "Test6"
    assert conso_quarter.second.reload.wrestler1.name == "Test3"
    assert conso_quarter.second.reload.wrestler2.name == "Test9"

    winner_by_name("Test5",semis.first)
    winner_by_name("Test10",semis.second)
    winner_by_name("Test2", conso_quarter.first)
    winner_by_name("Test3", conso_quarter.second)

    conso_semis = matches.select{|m| m.bracket_position == "Conso Semis"}.sort_by{|m| m.bracket_position_number}
    assert conso_semis.first.reload.wrestler1.name == "Test1"
    assert conso_semis.first.reload.wrestler2.name == "Test2"
    assert conso_semis.second.reload.wrestler1.name == "Test13"
    assert conso_semis.second.reload.wrestler2.name == "Test3"

    winner_by_name("Test2",conso_semis.first)
    winner_by_name("Test3",conso_semis.second)

    first_finals = matches.select{|m| m.bracket_position == "1/2"}.first
    third_finals = matches.select{|m| m.bracket_position == "3/4"}.first
    fifth_finals = matches.select{|m| m.bracket_position == "5/6"}.first

    assert first_finals.reload.wrestler1.name == "Test5"
    assert first_finals.reload.wrestler2.name == "Test10"

    assert third_finals.reload.wrestler1.name == "Test2"
    assert third_finals.reload.wrestler2.name == "Test3"

    assert fifth_finals.reload.wrestler1.name == "Test1"
    assert fifth_finals.reload.wrestler2.name == "Test13"

    # DEBUG
    # matches.sort_by{|m| m.bout_number}.each do |match|
    #   match.reload
    #   puts "Round #{match.round} #{match.w1_bracket_name} vs #{match.w2_bracket_name}"
    # end
  end
end