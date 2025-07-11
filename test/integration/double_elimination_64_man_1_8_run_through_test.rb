require 'test_helper'

class DoubleEliminationSixtyFourManEightPlacesRunThrough < ActionDispatch::IntegrationTest
  def setup
    create_double_elim_tournament_single_weight(62, "Regular Double Elimination 1-8")
    @matches = @tournament.matches.reload
  end

  def simulate_match(winner_name, match)
    wrestler = @tournament.wrestlers.find_by(name: winner_name)
    match.update!(
      winner_id: wrestler.id,
      finished: 1,
      win_type: "Decision",
      score: "1-0"
    )
  end

  test "32 man double elimination place 1-8" do
    create_double_elim_tournament_single_weight(62, "Regular Double Elimination 1-8")
    matches = @tournament.matches.reload

    bracket_r64 = matches.select{|m| m.bracket_position == "Bracket Round of 64"}
    winner_by_name("Test32", bracket_r64.select{|m| m.bracket_position_number == 2}.first)
    winner_by_name("Test48", bracket_r64.select{|m| m.bracket_position_number == 3}.first)
    winner_by_name("Test16", bracket_r64.select{|m| m.bracket_position_number == 4}.first)

    # Match  1  - seed  1  vs seed 64 (BYE)
    assert matches_r64[0].wrestler1.bracket_line == 1
    assert matches_r64[0].loser2_name == "BYE"

    # Match  2  - seed 32 vs seed 33
    assert matches_r64[1].wrestler1.bracket_line == 32
    assert matches_r64[1].wrestler2.bracket_line == 33

    # Match  3  - seed 17 vs seed 48
    assert matches_r64[2].wrestler1.bracket_line == 17
    assert matches_r64[2].wrestler2.bracket_line == 48

    # Match  4  - seed 16 vs seed 49
    assert matches_r64[3].wrestler1.bracket_line == 16
    assert matches_r64[3].wrestler2.bracket_line == 49

    # Match  5  - seed  9 vs seed 56
    assert matches_r64[4].wrestler1.bracket_line == 9
    assert matches_r64[4].wrestler2.bracket_line == 56

    # Match  6  - seed 24 vs seed 41
    assert matches_r64[5].wrestler1.bracket_line == 24
    assert matches_r64[5].wrestler2.bracket_line == 41

    # Match  7  - seed 25 vs seed 40
    assert matches_r64[6].wrestler1.bracket_line == 25
    assert matches_r64[6].wrestler2.bracket_line == 40

    # Match  8  - seed  8 vs seed 57
    assert matches_r64[7].wrestler1.bracket_line == 8
    assert matches_r64[7].wrestler2.bracket_line == 57

    # Match  9  - seed  5 vs seed 60
    assert matches_r64[8].wrestler1.bracket_line == 5
    assert matches_r64[8].wrestler2.bracket_line == 60

    # Match 10  - seed 28 vs seed 37
    assert matches_r64[9].wrestler1.bracket_line == 28
    assert matches_r64[9].wrestler2.bracket_line == 37

    # Match 11  - seed 21 vs seed 44
    assert matches_r64[10].wrestler1.bracket_line == 21
    assert matches_r64[10].wrestler2.bracket_line == 44

    # Match 12  - seed 12 vs seed 53
    assert matches_r64[11].wrestler1.bracket_line == 12
    assert matches_r64[11].wrestler2.bracket_line == 53

    # Match 13  - seed 13 vs seed 52
    assert matches_r64[12].wrestler1.bracket_line == 13
    assert matches_r64[12].wrestler2.bracket_line == 52

    # Match 14  - seed 20 vs seed 45
    assert matches_r64[13].wrestler1.bracket_line == 20
    assert matches_r64[13].wrestler2.bracket_line == 45

    # Match 15  - seed 29 vs seed 36
    assert matches_r64[14].wrestler1.bracket_line == 29
    assert matches_r64[14].wrestler2.bracket_line == 36

    # Match 16  - seed  4 vs seed 61
    assert matches_r64[15].wrestler1.bracket_line == 4
    assert matches_r64[15].wrestler2.bracket_line == 61

    # Match 17  - seed  3 vs seed 62
    assert matches_r64[16].wrestler1.bracket_line == 3
    assert matches_r64[16].wrestler2.bracket_line == 62

    # Match 18  - seed 30 vs seed 35
    assert matches_r64[17].wrestler1.bracket_line == 30
    assert matches_r64[17].wrestler2.bracket_line == 35

    # Match 19  - seed 19 vs seed 46
    assert matches_r64[18].wrestler1.bracket_line == 19
    assert matches_r64[18].wrestler2.bracket_line == 46

    # Match 20  - seed 14 vs seed 51
    assert matches_r64[19].wrestler1.bracket_line == 14
    assert matches_r64[19].wrestler2.bracket_line == 51

    # Match 21  - seed 11 vs seed 54
    assert matches_r64[20].wrestler1.bracket_line == 11
    assert matches_r64[20].wrestler2.bracket_line == 54

    # Match 22  - seed 22 vs seed 43
    assert matches_r64[21].wrestler1.bracket_line == 22
    assert matches_r64[21].wrestler2.bracket_line == 43

    # Match 23  - seed 27 vs seed 38
    assert matches_r64[22].wrestler1.bracket_line == 27
    assert matches_r64[22].wrestler2.bracket_line == 38

    # Match 24  - seed  6 vs seed 59
    assert matches_r64[23].wrestler1.bracket_line == 6
    assert matches_r64[23].wrestler2.bracket_line == 59

    # Match 25  - seed  7 vs seed 58
    assert matches_r64[24].wrestler1.bracket_line == 7
    assert matches_r64[24].wrestler2.bracket_line == 58

    # Match 26  - seed 26 vs seed 39
    assert matches_r64[25].wrestler1.bracket_line == 26
    assert matches_r64[25].wrestler2.bracket_line == 39

    # Match 27  - seed 23 vs seed 42
    assert matches_r64[26].wrestler1.bracket_line == 23
    assert matches_r64[26].wrestler2.bracket_line == 42

    # Match 28  - seed 10 vs seed 55
    assert matches_r64[27].wrestler1.bracket_line == 10
    assert matches_r64[27].wrestler2.bracket_line == 55

    # Match 29  - seed 15 vs seed 50
    assert matches_r64[28].wrestler1.bracket_line == 15
    assert matches_r64[28].wrestler2.bracket_line == 50

    # Match 30  - seed 18 vs seed 47
    assert matches_r64[29].wrestler1.bracket_line == 18
    assert matches_r64[29].wrestler2.bracket_line == 47

    # Match 31  - seed 31 vs seed 34
    assert matches_r64[30].wrestler1.bracket_line == 31
    assert matches_r64[30].wrestler2.bracket_line == 34

    # Match 32  - seed  2 vs seed 63 (BYE)
    assert matches_r64[31].wrestler1.bracket_line == 2
    assert matches_r64[31].loser2_name == "BYE"


    bracket_r32 = matches.select{|m| m.bracket_position == "Bracket Round of 32"}
    winner_by_name("Test17", bracket_r32.select{|m| m.bracket_position_number == 2}.first)
    winner_by_name("Test9", bracket_r32.select{|m| m.bracket_position_number == 3}.first)
    winner_by_name("Test25", bracket_r32.select{|m| m.bracket_position_number == 4}.first)
    winner_by_name("Test5", bracket_r32.select{|m| m.bracket_position_number == 5}.first)
    winner_by_name("Test12", bracket_r32.select{|m| m.bracket_position_number == 6}.first)
    winner_by_name("Test20", bracket_r32.select{|m| m.bracket_position_number == 7}.first)
    winner_by_name("Test4", bracket_r32.select{|m| m.bracket_position_number == 8}.first)
    winner_by_name("Test3", bracket_r32.select{|m| m.bracket_position_number == 9}.first)
    winner_by_name("Test14", bracket_r32.select{|m| m.bracket_position_number == 10}.first)
    winner_by_name("Test11", bracket_r32.select{|m| m.bracket_position_number == 11}.first)
    winner_by_name("Test6", bracket_r32.select{|m| m.bracket_position_number == 12}.first)
    winner_by_name("Test7", bracket_r32.select{|m| m.bracket_position_number == 13}.first)
    winner_by_name("Test10", bracket_r32.select{|m| m.bracket_position_number == 14}.first)
    winner_by_name("Test18", bracket_r32.select{|m| m.bracket_position_number == 15}.first)

    bracket_r16 = matches.reload.select{|m| m.bracket_position == "Bracket Round of 16"}.sort_by{|m| m.bracket_position_number}
    assert bracket_r16.select{|m| m.bracket_position_number == 1}.first.reload.wrestler1.name == "Test1"
    assert bracket_r16.select{|m| m.bracket_position_number == 1}.first.reload.wrestler2.name == "Test17"
    assert bracket_r16.select{|m| m.bracket_position_number == 2}.first.reload.wrestler1.name == "Test9"
    assert bracket_r16.select{|m| m.bracket_position_number == 2}.first.reload.wrestler2.name == "Test25"
    assert bracket_r16.select{|m| m.bracket_position_number == 3}.first.reload.wrestler1.name == "Test5"
    assert bracket_r16.select{|m| m.bracket_position_number == 3}.first.reload.wrestler2.name == "Test12"
    assert bracket_r16.select{|m| m.bracket_position_number == 4}.first.reload.wrestler1.name == "Test20"
    assert bracket_r16.select{|m| m.bracket_position_number == 4}.first.reload.wrestler2.name == "Test4"
    assert bracket_r16.select{|m| m.bracket_position_number == 5}.first.reload.wrestler1.name == "Test3"
    assert bracket_r16.select{|m| m.bracket_position_number == 5}.first.reload.wrestler2.name == "Test14"
    assert bracket_r16.select{|m| m.bracket_position_number == 6}.first.reload.wrestler1.name == "Test11"
    assert bracket_r16.select{|m| m.bracket_position_number == 6}.first.reload.wrestler2.name == "Test6"
    assert bracket_r16.select{|m| m.bracket_position_number == 7}.first.reload.wrestler1.name == "Test7"
    assert bracket_r16.select{|m| m.bracket_position_number == 7}.first.reload.wrestler2.name == "Test10"
    assert bracket_r16.select{|m| m.bracket_position_number == 8}.first.reload.wrestler1.name == "Test18"
    assert bracket_r16.select{|m| m.bracket_position_number == 8}.first.reload.wrestler2.name == "Test2"
    winner_by_name("Test1", bracket_r16.select{|m| m.bracket_position_number == 1}.first)
    winner_by_name("Test25", bracket_r16.select{|m| m.bracket_position_number == 2}.first)
    winner_by_name("Test5", bracket_r16.select{|m| m.bracket_position_number == 3}.first)
    winner_by_name("Test4", bracket_r16.select{|m| m.bracket_position_number == 4}.first)
    winner_by_name("Test3", bracket_r16.select{|m| m.bracket_position_number == 5}.first)
    winner_by_name("Test11", bracket_r16.select{|m| m.bracket_position_number == 6}.first)
    winner_by_name("Test10", bracket_r16.select{|m| m.bracket_position_number == 7}.first)
    winner_by_name("Test2", bracket_r16.select{|m| m.bracket_position_number == 8}.first)

    conso_r16_1 = matches.reload.select{|m| m.bracket_position == "Conso Round of 16.1"}.sort_by{|m| m.bracket_position_number}
    assert conso_r16_1.select{|m| m.bracket_position_number == 1}.first.reload.loser1_name == "BYE"
    assert conso_r16_1.select{|m| m.bracket_position_number == 1}.first.reload.wrestler2.name == "Test16"
    assert conso_r16_1.select{|m| m.bracket_position_number == 2}.first.reload.wrestler1.name == "Test24"
    assert conso_r16_1.select{|m| m.bracket_position_number == 2}.first.reload.wrestler2.name == "Test8"
    assert conso_r16_1.select{|m| m.bracket_position_number == 3}.first.reload.wrestler1.name == "Test28"
    assert conso_r16_1.select{|m| m.bracket_position_number == 3}.first.reload.wrestler2.name == "Test21"
    assert conso_r16_1.select{|m| m.bracket_position_number == 4}.first.reload.wrestler1.name == "Test13"
    assert conso_r16_1.select{|m| m.bracket_position_number == 4}.first.reload.wrestler2.name == "Test29"
    assert conso_r16_1.select{|m| m.bracket_position_number == 5}.first.reload.wrestler1.name == "Test30"
    assert conso_r16_1.select{|m| m.bracket_position_number == 5}.first.reload.wrestler2.name == "Test19"
    assert conso_r16_1.select{|m| m.bracket_position_number == 6}.first.reload.wrestler1.name == "Test22"
    assert conso_r16_1.select{|m| m.bracket_position_number == 6}.first.reload.wrestler2.name == "Test27"
    assert conso_r16_1.select{|m| m.bracket_position_number == 7}.first.reload.wrestler1.name == "Test26"
    assert conso_r16_1.select{|m| m.bracket_position_number == 7}.first.reload.wrestler2.name == "Test23"
    assert conso_r16_1.select{|m| m.bracket_position_number == 8}.first.reload.wrestler1.name == "Test15"
    assert conso_r16_1.select{|m| m.bracket_position_number == 8}.first.reload.loser2_name == "BYE"
    winner_by_name("Test8", conso_r16_1.select{|m| m.bracket_position_number == 2}.first)
    winner_by_name("Test21", conso_r16_1.select{|m| m.bracket_position_number == 3}.first)
    winner_by_name("Test29", conso_r16_1.select{|m| m.bracket_position_number == 4}.first)
    winner_by_name("Test19", conso_r16_1.select{|m| m.bracket_position_number == 5}.first)
    winner_by_name("Test22", conso_r16_1.select{|m| m.bracket_position_number == 6}.first)
    winner_by_name("Test23", conso_r16_1.select{|m| m.bracket_position_number == 7}.first)

    conso_r16_2 = matches.reload.select{|m| m.bracket_position == "Conso Round of 16.2"}.sort_by{|m| m.bracket_position_number}
    assert conso_r16_2.select{|m| m.bracket_position_number == 1}.first.reload.wrestler1.name == "Test18"
    assert conso_r16_2.select{|m| m.bracket_position_number == 1}.first.reload.wrestler2.name == "Test16"
    assert conso_r16_2.select{|m| m.bracket_position_number == 2}.first.reload.wrestler1.name == "Test7"
    assert conso_r16_2.select{|m| m.bracket_position_number == 2}.first.reload.wrestler2.name == "Test8"
    assert conso_r16_2.select{|m| m.bracket_position_number == 3}.first.reload.wrestler1.name == "Test6"
    assert conso_r16_2.select{|m| m.bracket_position_number == 3}.first.reload.wrestler2.name == "Test21"
    assert conso_r16_2.select{|m| m.bracket_position_number == 4}.first.reload.wrestler1.name == "Test14"
    assert conso_r16_2.select{|m| m.bracket_position_number == 4}.first.reload.wrestler2.name == "Test29"
    assert conso_r16_2.select{|m| m.bracket_position_number == 5}.first.reload.wrestler1.name == "Test20"
    assert conso_r16_2.select{|m| m.bracket_position_number == 5}.first.reload.wrestler2.name == "Test19"
    assert conso_r16_2.select{|m| m.bracket_position_number == 6}.first.reload.wrestler1.name == "Test12"
    assert conso_r16_2.select{|m| m.bracket_position_number == 6}.first.reload.wrestler2.name == "Test22"
    assert conso_r16_2.select{|m| m.bracket_position_number == 7}.first.reload.wrestler1.name == "Test9"
    assert conso_r16_2.select{|m| m.bracket_position_number == 7}.first.reload.wrestler2.name == "Test23"
    assert conso_r16_2.select{|m| m.bracket_position_number == 8}.first.reload.wrestler1.name == "Test17"
    assert conso_r16_2.select{|m| m.bracket_position_number == 8}.first.reload.wrestler2.name == "Test15"
    winner_by_name("Test16", conso_r16_2.select{|m| m.bracket_position_number == 1}.first)
    winner_by_name("Test8", conso_r16_2.select{|m| m.bracket_position_number == 2}.first)
    winner_by_name("Test6", conso_r16_2.select{|m| m.bracket_position_number == 3}.first)
    winner_by_name("Test29", conso_r16_2.select{|m| m.bracket_position_number == 4}.first)
    winner_by_name("Test20", conso_r16_2.select{|m| m.bracket_position_number == 5}.first)
    winner_by_name("Test12", conso_r16_2.select{|m| m.bracket_position_number == 6}.first)
    winner_by_name("Test23", conso_r16_2.select{|m| m.bracket_position_number == 7}.first)
    winner_by_name("Test17", conso_r16_2.select{|m| m.bracket_position_number == 8}.first)

    conso_r8_1 = matches.reload.select{|m| m.bracket_position == "Conso Round of 8.1"}.sort_by{|m| m.bracket_position_number}
    assert conso_r8_1.select{|m| m.bracket_position_number == 1}.first.reload.wrestler1.name == "Test16"
    assert conso_r8_1.select{|m| m.bracket_position_number == 1}.first.reload.wrestler2.name == "Test8"
    assert conso_r8_1.select{|m| m.bracket_position_number == 2}.first.reload.wrestler1.name == "Test6"
    assert conso_r8_1.select{|m| m.bracket_position_number == 2}.first.reload.wrestler2.name == "Test29"
    assert conso_r8_1.select{|m| m.bracket_position_number == 3}.first.reload.wrestler1.name == "Test20"
    assert conso_r8_1.select{|m| m.bracket_position_number == 3}.first.reload.wrestler2.name == "Test12"
    assert conso_r8_1.select{|m| m.bracket_position_number == 4}.first.reload.wrestler1.name == "Test23"
    assert conso_r8_1.select{|m| m.bracket_position_number == 4}.first.reload.wrestler2.name == "Test17"
    winner_by_name("Test8", conso_r8_1.select{|m| m.bracket_position_number == 1}.first)
    winner_by_name("Test6", conso_r8_1.select{|m| m.bracket_position_number == 2}.first)
    winner_by_name("Test20", conso_r8_1.select{|m| m.bracket_position_number == 3}.first)
    winner_by_name("Test17", conso_r8_1.select{|m| m.bracket_position_number == 4}.first)

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

    conso_r8_2 = matches.reload.select{|m| m.bracket_position == "Conso Round of 8.2"}.sort_by{|m| m.bracket_position_number}
    assert conso_r8_2.select{|m| m.bracket_position_number == 1}.first.reload.wrestler1.name == "Test25"
    assert conso_r8_2.select{|m| m.bracket_position_number == 1}.first.reload.wrestler2.name == "Test8"
    assert conso_r8_2.select{|m| m.bracket_position_number == 2}.first.reload.wrestler1.name == "Test4"
    assert conso_r8_2.select{|m| m.bracket_position_number == 2}.first.reload.wrestler2.name == "Test6"
    assert conso_r8_2.select{|m| m.bracket_position_number == 3}.first.reload.wrestler1.name == "Test3"
    assert conso_r8_2.select{|m| m.bracket_position_number == 3}.first.reload.wrestler2.name == "Test20"
    assert conso_r8_2.select{|m| m.bracket_position_number == 4}.first.reload.wrestler1.name == "Test10"
    assert conso_r8_2.select{|m| m.bracket_position_number == 4}.first.reload.wrestler2.name == "Test17"
    winner_by_name("Test8", conso_r8_2.select{|m| m.bracket_position_number == 1}.first)
    winner_by_name("Test6", conso_r8_2.select{|m| m.bracket_position_number == 2}.first)
    winner_by_name("Test3", conso_r8_2.select{|m| m.bracket_position_number == 3}.first)
    winner_by_name("Test10", conso_r8_2.select{|m| m.bracket_position_number == 4}.first)

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
