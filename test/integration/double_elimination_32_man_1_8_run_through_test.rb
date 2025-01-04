require 'test_helper'

class DoubleEliminationThirtyTwoManEightPlacesRunThrough < ActionDispatch::IntegrationTest
  def setup
  end

  def winner_by_name(winner_name,match)
    wrestler = @tournament.weights.first.wrestlers.select{|w| w.name == winner_name}.first
    match.winner_id = wrestler.id
    match.finished = 1
    match.win_type = "Decision"
    match.score = "1-0"
    match.save
  end

  test "32 man double elimination place 1-8" do
    create_double_elim_tournament_single_weight(30, "Regular Double Elimination 1-8")
    matches = @tournament.matches.reload

    round1 = matches.select{|m| m.round == 1}
    winner_by_name("Test17", round1.select{|m| m.bracket_position_number == 2}.first)
    winner_by_name("Test9", round1.select{|m| m.bracket_position_number == 3}.first)
    winner_by_name("Test25", round1.select{|m| m.bracket_position_number == 4}.first)
    winner_by_name("Test5", round1.select{|m| m.bracket_position_number == 5}.first)
    winner_by_name("Test12", round1.select{|m| m.bracket_position_number == 6}.first)
    winner_by_name("Test20", round1.select{|m| m.bracket_position_number == 7}.first)
    winner_by_name("Test4", round1.select{|m| m.bracket_position_number == 8}.first)
    winner_by_name("Test3", round1.select{|m| m.bracket_position_number == 9}.first)
    winner_by_name("Test14", round1.select{|m| m.bracket_position_number == 10}.first)
    winner_by_name("Test11", round1.select{|m| m.bracket_position_number == 11}.first)
    winner_by_name("Test6", round1.select{|m| m.bracket_position_number == 12}.first)
    winner_by_name("Test7", round1.select{|m| m.bracket_position_number == 13}.first)
    winner_by_name("Test10", round1.select{|m| m.bracket_position_number == 14}.first)
    winner_by_name("Test18", round1.select{|m| m.bracket_position_number == 15}.first)

    round2_championship = matches.reload.select{|m| m.bracket_position == "Bracket" and m.round == 2}.sort_by{|m| m.bracket_position_number}
    assert round2_championship.select{|m| m.bracket_position_number == 1}.first.reload.wrestler1.name == "Test1"
    assert round2_championship.select{|m| m.bracket_position_number == 1}.first.reload.wrestler2.name == "Test17"
    assert round2_championship.select{|m| m.bracket_position_number == 2}.first.reload.wrestler1.name == "Test9"
    assert round2_championship.select{|m| m.bracket_position_number == 2}.first.reload.wrestler2.name == "Test25"
    assert round2_championship.select{|m| m.bracket_position_number == 3}.first.reload.wrestler1.name == "Test5"
    assert round2_championship.select{|m| m.bracket_position_number == 3}.first.reload.wrestler2.name == "Test12"
    assert round2_championship.select{|m| m.bracket_position_number == 4}.first.reload.wrestler1.name == "Test20"
    assert round2_championship.select{|m| m.bracket_position_number == 4}.first.reload.wrestler2.name == "Test4"
    assert round2_championship.select{|m| m.bracket_position_number == 5}.first.reload.wrestler1.name == "Test3"
    assert round2_championship.select{|m| m.bracket_position_number == 5}.first.reload.wrestler2.name == "Test14"
    assert round2_championship.select{|m| m.bracket_position_number == 6}.first.reload.wrestler1.name == "Test11"
    assert round2_championship.select{|m| m.bracket_position_number == 6}.first.reload.wrestler2.name == "Test6"
    assert round2_championship.select{|m| m.bracket_position_number == 7}.first.reload.wrestler1.name == "Test7"
    assert round2_championship.select{|m| m.bracket_position_number == 7}.first.reload.wrestler2.name == "Test10"
    assert round2_championship.select{|m| m.bracket_position_number == 8}.first.reload.wrestler1.name == "Test18"
    assert round2_championship.select{|m| m.bracket_position_number == 8}.first.reload.wrestler2.name == "Test2"
    winner_by_name("Test1", round2_championship.select{|m| m.bracket_position_number == 1}.first)
    winner_by_name("Test25", round2_championship.select{|m| m.bracket_position_number == 2}.first)
    winner_by_name("Test5", round2_championship.select{|m| m.bracket_position_number == 3}.first)
    winner_by_name("Test4", round2_championship.select{|m| m.bracket_position_number == 4}.first)
    winner_by_name("Test3", round2_championship.select{|m| m.bracket_position_number == 5}.first)
    winner_by_name("Test11", round2_championship.select{|m| m.bracket_position_number == 6}.first)
    winner_by_name("Test10", round2_championship.select{|m| m.bracket_position_number == 7}.first)
    winner_by_name("Test2", round2_championship.select{|m| m.bracket_position_number == 8}.first)

    round2_conso = matches.reload.select{|m| m.bracket_position == "Conso" and m.round == 2}.sort_by{|m| m.bracket_position_number}
    assert round2_conso.select{|m| m.bracket_position_number == 1}.first.reload.loser1_name == "BYE"
    assert round2_conso.select{|m| m.bracket_position_number == 1}.first.reload.wrestler2.name == "Test16"
    assert round2_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler1.name == "Test24"
    assert round2_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler2.name == "Test8"
    assert round2_conso.select{|m| m.bracket_position_number == 3}.first.reload.wrestler1.name == "Test28"
    assert round2_conso.select{|m| m.bracket_position_number == 3}.first.reload.wrestler2.name == "Test21"
    assert round2_conso.select{|m| m.bracket_position_number == 4}.first.reload.wrestler1.name == "Test13"
    assert round2_conso.select{|m| m.bracket_position_number == 4}.first.reload.wrestler2.name == "Test29"
    assert round2_conso.select{|m| m.bracket_position_number == 5}.first.reload.wrestler1.name == "Test30"
    assert round2_conso.select{|m| m.bracket_position_number == 5}.first.reload.wrestler2.name == "Test19"
    assert round2_conso.select{|m| m.bracket_position_number == 6}.first.reload.wrestler1.name == "Test22"
    assert round2_conso.select{|m| m.bracket_position_number == 6}.first.reload.wrestler2.name == "Test27"
    assert round2_conso.select{|m| m.bracket_position_number == 7}.first.reload.wrestler1.name == "Test26"
    assert round2_conso.select{|m| m.bracket_position_number == 7}.first.reload.wrestler2.name == "Test23"
    assert round2_conso.select{|m| m.bracket_position_number == 8}.first.reload.wrestler1.name == "Test15"
    assert round2_conso.select{|m| m.bracket_position_number == 8}.first.reload.loser2_name == "BYE"
    winner_by_name("Test8", round2_conso.select{|m| m.bracket_position_number == 2}.first)
    winner_by_name("Test21", round2_conso.select{|m| m.bracket_position_number == 3}.first)
    winner_by_name("Test29", round2_conso.select{|m| m.bracket_position_number == 4}.first)
    winner_by_name("Test19", round2_conso.select{|m| m.bracket_position_number == 5}.first)
    winner_by_name("Test22", round2_conso.select{|m| m.bracket_position_number == 6}.first)
    winner_by_name("Test23", round2_conso.select{|m| m.bracket_position_number == 7}.first)

    round3_conso = matches.reload.select{|m| m.bracket_position == "Conso" and m.round == 3}.sort_by{|m| m.bracket_position_number}
    assert round3_conso.select{|m| m.bracket_position_number == 1}.first.reload.wrestler1.name == "Test18"
    assert round3_conso.select{|m| m.bracket_position_number == 1}.first.reload.wrestler2.name == "Test16"
    assert round3_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler1.name == "Test7"
    assert round3_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler2.name == "Test8"
    assert round3_conso.select{|m| m.bracket_position_number == 3}.first.reload.wrestler1.name == "Test6"
    assert round3_conso.select{|m| m.bracket_position_number == 3}.first.reload.wrestler2.name == "Test21"
    assert round3_conso.select{|m| m.bracket_position_number == 4}.first.reload.wrestler1.name == "Test14"
    assert round3_conso.select{|m| m.bracket_position_number == 4}.first.reload.wrestler2.name == "Test29"
    assert round3_conso.select{|m| m.bracket_position_number == 5}.first.reload.wrestler1.name == "Test20"
    assert round3_conso.select{|m| m.bracket_position_number == 5}.first.reload.wrestler2.name == "Test19"
    assert round3_conso.select{|m| m.bracket_position_number == 6}.first.reload.wrestler1.name == "Test12"
    assert round3_conso.select{|m| m.bracket_position_number == 6}.first.reload.wrestler2.name == "Test22"
    assert round3_conso.select{|m| m.bracket_position_number == 7}.first.reload.wrestler1.name == "Test9"
    assert round3_conso.select{|m| m.bracket_position_number == 7}.first.reload.wrestler2.name == "Test23"
    assert round3_conso.select{|m| m.bracket_position_number == 8}.first.reload.wrestler1.name == "Test17"
    assert round3_conso.select{|m| m.bracket_position_number == 8}.first.reload.wrestler2.name == "Test15"
    winner_by_name("Test16", round3_conso.select{|m| m.bracket_position_number == 1}.first)
    winner_by_name("Test8", round3_conso.select{|m| m.bracket_position_number == 2}.first)
    winner_by_name("Test6", round3_conso.select{|m| m.bracket_position_number == 3}.first)
    winner_by_name("Test29", round3_conso.select{|m| m.bracket_position_number == 4}.first)
    winner_by_name("Test20", round3_conso.select{|m| m.bracket_position_number == 5}.first)
    winner_by_name("Test12", round3_conso.select{|m| m.bracket_position_number == 6}.first)
    winner_by_name("Test23", round3_conso.select{|m| m.bracket_position_number == 7}.first)
    winner_by_name("Test17", round3_conso.select{|m| m.bracket_position_number == 8}.first)

    round4_conso = matches.reload.select{|m| m.bracket_position == "Conso" and m.round == 4}.sort_by{|m| m.bracket_position_number}
    assert round4_conso.select{|m| m.bracket_position_number == 1}.first.reload.wrestler1.name == "Test16"
    assert round4_conso.select{|m| m.bracket_position_number == 1}.first.reload.wrestler2.name == "Test8"
    assert round4_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler1.name == "Test6"
    assert round4_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler2.name == "Test29"
    assert round4_conso.select{|m| m.bracket_position_number == 3}.first.reload.wrestler1.name == "Test20"
    assert round4_conso.select{|m| m.bracket_position_number == 3}.first.reload.wrestler2.name == "Test12"
    assert round4_conso.select{|m| m.bracket_position_number == 4}.first.reload.wrestler1.name == "Test23"
    assert round4_conso.select{|m| m.bracket_position_number == 4}.first.reload.wrestler2.name == "Test17"
    winner_by_name("Test8", round4_conso.select{|m| m.bracket_position_number == 1}.first)
    winner_by_name("Test6", round4_conso.select{|m| m.bracket_position_number == 2}.first)
    winner_by_name("Test20", round4_conso.select{|m| m.bracket_position_number == 3}.first)
    winner_by_name("Test17", round4_conso.select{|m| m.bracket_position_number == 4}.first)

    quarters = matches.reload.select{|m| m.bracket_position == "Quarter"}.sort_by{|m| m.bracket_position_number}
    assert quarters.select{|m| m.bracket_position_number == 1}.first.reload.wrestler1.name == "Test1"
    assert quarters.select{|m| m.bracket_position_number == 1}.first.reload.wrestler2.name == "Test25"
    assert quarters.select{|m| m.bracket_position_number == 2}.first.reload.wrestler1.name == "Test5"
    assert quarters.select{|m| m.bracket_position_number == 2}.first.reload.wrestler2.name == "Test4"
    assert quarters.select{|m| m.bracket_position_number == 3}.first.reload.wrestler1.name == "Test3"
    assert quarters.select{|m| m.bracket_position_number == 3}.first.reload.wrestler2.name == "Test11"
    assert quarters.select{|m| m.bracket_position_number == 4}.first.reload.wrestler1.name == "Test10"
    assert quarters.select{|m| m.bracket_position_number == 4}.first.reload.wrestler2.name == "Test2"
    winner_by_name("Test1", quarters.select{|m| m.bracket_position_number == 1}.first)
    winner_by_name("Test5", quarters.select{|m| m.bracket_position_number == 2}.first)
    winner_by_name("Test11", quarters.select{|m| m.bracket_position_number == 3}.first)
    winner_by_name("Test2", quarters.select{|m| m.bracket_position_number == 4}.first)

    round5_conso = matches.reload.select{|m| m.bracket_position == "Conso" and m.round == 5}.sort_by{|m| m.bracket_position_number}
    assert round5_conso.select{|m| m.bracket_position_number == 1}.first.reload.wrestler1.name == "Test25"
    assert round5_conso.select{|m| m.bracket_position_number == 1}.first.reload.wrestler2.name == "Test8"
    assert round5_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler1.name == "Test4"
    assert round5_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler2.name == "Test6"
    assert round5_conso.select{|m| m.bracket_position_number == 3}.first.reload.wrestler1.name == "Test3"
    assert round5_conso.select{|m| m.bracket_position_number == 3}.first.reload.wrestler2.name == "Test20"
    assert round5_conso.select{|m| m.bracket_position_number == 4}.first.reload.wrestler1.name == "Test10"
    assert round5_conso.select{|m| m.bracket_position_number == 4}.first.reload.wrestler2.name == "Test17"
    winner_by_name("Test8", round5_conso.select{|m| m.bracket_position_number == 1}.first)
    winner_by_name("Test6", round5_conso.select{|m| m.bracket_position_number == 2}.first)
    winner_by_name("Test3", round5_conso.select{|m| m.bracket_position_number == 3}.first)
    winner_by_name("Test10", round5_conso.select{|m| m.bracket_position_number == 4}.first)

    quarters_conso = matches.reload.select{|m| m.bracket_position == "Conso Quarter"}.sort_by{|m| m.bracket_position_number}
    assert quarters_conso.select{|m| m.bracket_position_number == 1}.first.reload.wrestler1.name == "Test8"
    assert quarters_conso.select{|m| m.bracket_position_number == 1}.first.reload.wrestler2.name == "Test6"
    assert quarters_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler1.name == "Test3"
    assert quarters_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler2.name == "Test10"
    winner_by_name("Test8", quarters_conso.select{|m| m.bracket_position_number == 1}.first)
    winner_by_name("Test3", quarters_conso.select{|m| m.bracket_position_number == 2}.first)

    semis = matches.reload.select{|m| m.bracket_position == "Semis"}.sort_by{|m| m.bracket_position_number}
    assert semis.select{|m| m.bracket_position_number == 1}.first.reload.wrestler1.name == "Test1"
    assert semis.select{|m| m.bracket_position_number == 1}.first.reload.wrestler2.name == "Test5"
    assert semis.select{|m| m.bracket_position_number == 2}.first.reload.wrestler1.name == "Test11"
    assert semis.select{|m| m.bracket_position_number == 2}.first.reload.wrestler2.name == "Test2"
    winner_by_name("Test5", semis.select{|m| m.bracket_position_number == 1}.first)
    winner_by_name("Test2", semis.select{|m| m.bracket_position_number == 2}.first)

    semis_conso = matches.reload.select{|m| m.bracket_position == "Conso Semis"}.sort_by{|m| m.bracket_position_number}
    assert semis_conso.select{|m| m.bracket_position_number == 1}.first.reload.wrestler1.name == "Test11"
    assert semis_conso.select{|m| m.bracket_position_number == 1}.first.reload.wrestler2.name == "Test8"
    assert semis_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler1.name == "Test1"
    assert semis_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler2.name == "Test3"
    winner_by_name("Test11", semis_conso.select{|m| m.bracket_position_number == 1}.first)
    winner_by_name("Test3", semis_conso.select{|m| m.bracket_position_number == 2}.first)

    first_finals = matches.select{|m| m.bracket_position == "1/2"}.first
    third_finals = matches.select{|m| m.bracket_position == "3/4"}.first
    fifth_finals = matches.select{|m| m.bracket_position == "5/6"}.first
    seventh_finals = matches.select{|m| m.bracket_position == "7/8"}.first

    assert first_finals.reload.wrestler1.name == "Test5"
    assert first_finals.reload.wrestler2.name == "Test2"

    assert third_finals.reload.wrestler1.name == "Test11"
    assert third_finals.reload.wrestler2.name == "Test3"

    assert fifth_finals.reload.wrestler1.name == "Test8"
    assert fifth_finals.reload.wrestler2.name == "Test1"
    
    assert seventh_finals.reload.wrestler1.name == "Test6"
    assert seventh_finals.reload.wrestler2.name == "Test10"

    # DEBUG
    # matches.sort_by{|m| m.bout_number}.each do |match|
    #   match.reload
    #   puts "Round #{match.round} #{match.w1_bracket_name} vs #{match.w2_bracket_name}"
    # end
  end
end