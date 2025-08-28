require 'test_helper'

class DoubleEliminationSixtyFourManEightPlacesRunThrough < ActionDispatch::IntegrationTest
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

  test "64 man double elimination place 1-8" do
    create_double_elim_tournament_single_weight(62, "Regular Double Elimination 1-8")
    matches = @tournament.matches.reload
    # BYEs are automatically advanced
    bracket_r64 = matches.reload.select { |m| m.bracket_position == "Bracket Round of 64" }.sort_by(&:bracket_position_number)
    # winner_by_name("Test1", bracket_r64.select{|m| m.bracket_position_number == 1}.first) # seed 1 vs 64 (BYE)
    winner_by_name("Test32", bracket_r64.select{|m| m.bracket_position_number == 2}.first) # seed 32 vs seed 33
    winner_by_name("Test17", bracket_r64.select{|m| m.bracket_position_number == 3}.first) # seed 17 vs seed 48
    winner_by_name("Test49", bracket_r64.select{|m| m.bracket_position_number == 4}.first) # seed 16 vs seed 49
    winner_by_name("Test9", bracket_r64.select{|m| m.bracket_position_number == 5}.first) # seed  9 vs seed 56
    winner_by_name("Test24", bracket_r64.select{|m| m.bracket_position_number == 6}.first) # seed 24 vs seed 41
    winner_by_name("Test25", bracket_r64.select{|m| m.bracket_position_number == 7}.first) # seed 25 vs seed 40
    winner_by_name("Test8", bracket_r64.select{|m| m.bracket_position_number == 8}.first) # seed  8 vs seed 57
    winner_by_name("Test5", bracket_r64.select{|m| m.bracket_position_number == 9}.first) # seed  5 vs seed 60
    winner_by_name("Test37", bracket_r64.select{|m| m.bracket_position_number == 10}.first) # seed 28 vs seed 37
    winner_by_name("Test21", bracket_r64.select{|m| m.bracket_position_number == 11}.first) # seed 21 vs seed 44
    winner_by_name("Test12", bracket_r64.select{|m| m.bracket_position_number == 12}.first) # seed 12 vs seed 53
    winner_by_name("Test13", bracket_r64.select{|m| m.bracket_position_number == 13}.first) # seed 13 vs seed 52
    winner_by_name("Test20", bracket_r64.select{|m| m.bracket_position_number == 14}.first) # seed 20 vs 45
    winner_by_name("Test29", bracket_r64.select{|m| m.bracket_position_number == 15}.first) # seed 29 vs 36
    winner_by_name("Test4",  bracket_r64.select{|m| m.bracket_position_number == 16}.first) # seed 4 vs 61
    winner_by_name("Test3",  bracket_r64.select{|m| m.bracket_position_number == 17}.first) # seed 3 vs 62
    winner_by_name("Test30", bracket_r64.select{|m| m.bracket_position_number == 18}.first) # seed 30 vs 35
    winner_by_name("Test19", bracket_r64.select{|m| m.bracket_position_number == 19}.first) # seed 19 vs 46
    winner_by_name("Test14", bracket_r64.select{|m| m.bracket_position_number == 20}.first) # seed 14 vs 51
    winner_by_name("Test11", bracket_r64.select{|m| m.bracket_position_number == 21}.first) # seed 11 vs 54
    winner_by_name("Test22", bracket_r64.select{|m| m.bracket_position_number == 22}.first) # seed 22 vs 43
    winner_by_name("Test27", bracket_r64.select{|m| m.bracket_position_number == 23}.first) # seed 27 vs 38
    winner_by_name("Test6",  bracket_r64.select{|m| m.bracket_position_number == 24}.first) # seed 6 vs 59
    winner_by_name("Test7",  bracket_r64.select{|m| m.bracket_position_number == 25}.first) # seed 7 vs 58
    winner_by_name("Test26", bracket_r64.select{|m| m.bracket_position_number == 26}.first) # seed 26 vs 39
    winner_by_name("Test23", bracket_r64.select{|m| m.bracket_position_number == 27}.first) # seed 23 vs 42
    winner_by_name("Test10", bracket_r64.select{|m| m.bracket_position_number == 28}.first) # seed 10 vs 55
    winner_by_name("Test15", bracket_r64.select{|m| m.bracket_position_number == 29}.first) # seed 15 vs 50
    winner_by_name("Test18", bracket_r64.select{|m| m.bracket_position_number == 30}.first) # seed 18 vs 47
    winner_by_name("Test31", bracket_r64.select{|m| m.bracket_position_number == 31}.first) # seed 31 vs 34
    # BYE's auto move
    # winner_by_name("Test2",  bracket_r64.select{|m| m.bracket_position_number == 32}.first) # seed  2 vs seed 63 (BYE)

    bracket_r32 = matches.select{|m| m.bracket_position == "Bracket Round of 32"}
    assert bracket_r32.select{|m| m.bracket_position_number == 1}.first.reload.wrestler1.name == "Test1"
    assert bracket_r32.select{|m| m.bracket_position_number == 1}.first.reload.wrestler2.name == "Test32"
    winner_by_name("Test1", bracket_r32.select{|m| m.bracket_position_number == 1}.first)
    assert bracket_r32.select{|m| m.bracket_position_number == 2}.first.reload.wrestler1.name == "Test17"
    assert bracket_r32.select{|m| m.bracket_position_number == 2}.first.reload.wrestler2.name == "Test49"
    winner_by_name("Test17", bracket_r32.select{|m| m.bracket_position_number == 2}.first)
    assert bracket_r32.select{|m| m.bracket_position_number == 3}.first.reload.wrestler1.name == "Test9"
    assert bracket_r32.select{|m| m.bracket_position_number == 3}.first.reload.wrestler2.name == "Test24"
    winner_by_name("Test24", bracket_r32.select{|m| m.bracket_position_number == 3}.first)
    assert bracket_r32.select{|m| m.bracket_position_number == 4}.first.reload.wrestler1.name == "Test25"
    assert bracket_r32.select{|m| m.bracket_position_number == 4}.first.reload.wrestler2.name == "Test8"
    winner_by_name("Test8", bracket_r32.select{|m| m.bracket_position_number == 4}.first)
    assert bracket_r32.select{|m| m.bracket_position_number == 5}.first.reload.wrestler1.name == "Test5"
    assert bracket_r32.select{|m| m.bracket_position_number == 5}.first.reload.wrestler2.name == "Test37"
    winner_by_name("Test5", bracket_r32.select{|m| m.bracket_position_number == 5}.first)
    assert bracket_r32.select{|m| m.bracket_position_number == 6}.first.reload.wrestler1.name == "Test21"
    assert bracket_r32.select{|m| m.bracket_position_number == 6}.first.reload.wrestler2.name == "Test12"
    winner_by_name("Test21", bracket_r32.select{|m| m.bracket_position_number == 6}.first)
    assert bracket_r32.select{|m| m.bracket_position_number == 7}.first.reload.wrestler1.name == "Test13"
    assert bracket_r32.select{|m| m.bracket_position_number == 7}.first.reload.wrestler2.name == "Test20"
    winner_by_name("Test13", bracket_r32.select{|m| m.bracket_position_number == 7}.first)
    assert bracket_r32.select{|m| m.bracket_position_number == 8}.first.reload.wrestler1.name == "Test29"
    assert bracket_r32.select{|m| m.bracket_position_number == 8}.first.reload.wrestler2.name == "Test4"
    winner_by_name("Test4", bracket_r32.select{|m| m.bracket_position_number == 8}.first)
    assert bracket_r32.select{|m| m.bracket_position_number == 9}.first.reload.wrestler1.name == "Test3"
    assert bracket_r32.select{|m| m.bracket_position_number == 9}.first.reload.wrestler2.name == "Test30"
    winner_by_name("Test3", bracket_r32.select{|m| m.bracket_position_number == 9}.first)
    assert bracket_r32.select{|m| m.bracket_position_number == 10}.first.reload.wrestler1.name == "Test19"
    assert bracket_r32.select{|m| m.bracket_position_number == 10}.first.reload.wrestler2.name == "Test14"
    winner_by_name("Test19", bracket_r32.select{|m| m.bracket_position_number == 10}.first)
    assert bracket_r32.select{|m| m.bracket_position_number == 11}.first.reload.wrestler1.name == "Test11"
    assert bracket_r32.select{|m| m.bracket_position_number == 11}.first.reload.wrestler2.name == "Test22"
    winner_by_name("Test11", bracket_r32.select{|m| m.bracket_position_number == 11}.first)
    assert bracket_r32.select{|m| m.bracket_position_number == 12}.first.reload.wrestler1.name == "Test27"
    assert bracket_r32.select{|m| m.bracket_position_number == 12}.first.reload.wrestler2.name == "Test6"
    winner_by_name("Test27", bracket_r32.select{|m| m.bracket_position_number == 12}.first)
    assert bracket_r32.select{|m| m.bracket_position_number == 13}.first.reload.wrestler1.name == "Test7"
    assert bracket_r32.select{|m| m.bracket_position_number == 13}.first.reload.wrestler2.name == "Test26"
    winner_by_name("Test7", bracket_r32.select{|m| m.bracket_position_number == 13}.first)
    assert bracket_r32.select{|m| m.bracket_position_number == 14}.first.reload.wrestler1.name == "Test23"
    assert bracket_r32.select{|m| m.bracket_position_number == 14}.first.reload.wrestler2.name == "Test10"
    winner_by_name("Test23", bracket_r32.select{|m| m.bracket_position_number == 14}.first)
    assert bracket_r32.select{|m| m.bracket_position_number == 15}.first.reload.wrestler1.name == "Test15"
    assert bracket_r32.select{|m| m.bracket_position_number == 15}.first.reload.wrestler2.name == "Test18"
    winner_by_name("Test15", bracket_r32.select{|m| m.bracket_position_number == 15}.first)
    assert bracket_r32.select{|m| m.bracket_position_number == 16}.first.reload.wrestler1.name == "Test31"
    assert bracket_r32.select{|m| m.bracket_position_number == 16}.first.reload.wrestler2.name == "Test2"
    winner_by_name("Test2", bracket_r32.select{|m| m.bracket_position_number == 16}.first)

    conso_r32_1 = matches.reload.select { |m| m.bracket_position == "Conso Round of 32.1" }.sort_by(&:bracket_position_number)
    assert conso_r32_1[0].loser1_name == "BYE"
    assert conso_r32_1[0].wrestler2.name == "Test33"
    # BYE's auto move
    assert conso_r32_1[1].wrestler1.name == "Test48"
    assert conso_r32_1[1].wrestler2.name == "Test16"
    winner_by_name("Test16", conso_r32_1[1])
    assert conso_r32_1[2].wrestler1.name == "Test56"
    assert conso_r32_1[2].wrestler2.name == "Test41"
    winner_by_name("Test56", conso_r32_1[2])
    assert conso_r32_1[3].wrestler1.name == "Test40"
    assert conso_r32_1[3].wrestler2.name == "Test57"
    winner_by_name("Test57", conso_r32_1[3])
    assert conso_r32_1[4].wrestler1.name == "Test60"
    assert conso_r32_1[4].wrestler2.name == "Test28"
    winner_by_name("Test28", conso_r32_1[4])
    assert conso_r32_1[5].wrestler1.name == "Test44"
    assert conso_r32_1[5].wrestler2.name == "Test53"
    winner_by_name("Test53", conso_r32_1[5])
    assert conso_r32_1[6].wrestler1.name == "Test52"
    assert conso_r32_1[6].wrestler2.name == "Test45"
    winner_by_name("Test45", conso_r32_1[6])
    assert conso_r32_1[7].wrestler1.name == "Test36"
    assert conso_r32_1[7].wrestler2.name == "Test61"
    winner_by_name("Test61", conso_r32_1[7])
    assert conso_r32_1[8].wrestler1.name == "Test62"
    assert conso_r32_1[8].wrestler2.name == "Test35"
    winner_by_name("Test35", conso_r32_1[8])
    assert conso_r32_1[9].wrestler1.name == "Test46"
    assert conso_r32_1[9].wrestler2.name == "Test51"
    winner_by_name("Test51", conso_r32_1[9])
    assert conso_r32_1[10].wrestler1.name == "Test54"
    assert conso_r32_1[10].wrestler2.name == "Test43"
    winner_by_name("Test43", conso_r32_1[10])
    assert conso_r32_1[11].wrestler1.name == "Test38"
    assert conso_r32_1[11].wrestler2.name == "Test59"
    winner_by_name("Test59", conso_r32_1[11])
    assert conso_r32_1[12].wrestler1.name == "Test58"
    assert conso_r32_1[12].wrestler2.name == "Test39"
    winner_by_name("Test39", conso_r32_1[12])
    assert conso_r32_1[13].wrestler1.name == "Test42"
    assert conso_r32_1[13].wrestler2.name == "Test55"
    winner_by_name("Test55", conso_r32_1[13])
    assert conso_r32_1[14].wrestler1.name == "Test50"
    assert conso_r32_1[14].wrestler2.name == "Test47"
    winner_by_name("Test47", conso_r32_1[14])
    assert conso_r32_1[15].wrestler1.name == "Test34"
    assert conso_r32_1[15].loser2_name == "BYE"
    # Auto BYE

    conso_r32_2 = matches.reload.select { |m| m.bracket_position == "Conso Round of 32.2" }.sort_by(&:bracket_position_number)
    assert conso_r32_2[0].wrestler1.name == "Test31"
    assert conso_r32_2[0].wrestler2.name == "Test33"
    winner_by_name("Test31", conso_r32_2[0])
    assert conso_r32_2[1].wrestler1.name == "Test18"
    assert conso_r32_2[1].wrestler2.name == "Test16"
    winner_by_name("Test16", conso_r32_2[1])
    assert conso_r32_2[2].wrestler1.name == "Test10"
    assert conso_r32_2[2].wrestler2.name == "Test56"
    winner_by_name("Test10", conso_r32_2[2])
    assert conso_r32_2[3].wrestler1.name == "Test26"
    assert conso_r32_2[3].wrestler2.name == "Test57"
    winner_by_name("Test26", conso_r32_2[3])
    assert conso_r32_2[4].wrestler1.name == "Test6"
    assert conso_r32_2[4].wrestler2.name == "Test28"
    winner_by_name("Test6", conso_r32_2[4])
    assert conso_r32_2[5].wrestler1.name == "Test22"
    assert conso_r32_2[5].wrestler2.name == "Test53"
    winner_by_name("Test22", conso_r32_2[5])
    assert conso_r32_2[6].wrestler1.name == "Test14"
    assert conso_r32_2[6].wrestler2.name == "Test45"
    winner_by_name("Test45", conso_r32_2[6])
    assert conso_r32_2[7].wrestler1.name == "Test30"
    assert conso_r32_2[7].wrestler2.name == "Test61"
    winner_by_name("Test30", conso_r32_2[7])
    assert conso_r32_2[8].wrestler1.name == "Test29"
    assert conso_r32_2[8].wrestler2.name == "Test35"
    winner_by_name("Test35", conso_r32_2[8])
    assert conso_r32_2[9].wrestler1.name == "Test20"
    assert conso_r32_2[9].wrestler2.name == "Test51"
    winner_by_name("Test20", conso_r32_2[9])
    assert conso_r32_2[10].wrestler1.name == "Test12"
    assert conso_r32_2[10].wrestler2.name == "Test43"
    winner_by_name("Test43", conso_r32_2[10])
    assert conso_r32_2[11].wrestler1.name == "Test37"
    assert conso_r32_2[11].wrestler2.name == "Test59"
    winner_by_name("Test59", conso_r32_2[11])
    assert conso_r32_2[12].wrestler1.name == "Test25"
    assert conso_r32_2[12].wrestler2.name == "Test39"
    winner_by_name("Test25", conso_r32_2[12])
    assert conso_r32_2[13].wrestler1.name == "Test9"
    assert conso_r32_2[13].wrestler2.name == "Test55"
    winner_by_name("Test9", conso_r32_2[13])
    assert conso_r32_2[14].wrestler1.name == "Test49"
    assert conso_r32_2[14].wrestler2.name == "Test47"
    winner_by_name("Test47", conso_r32_2[14])
    assert conso_r32_2[15].wrestler1.name == "Test32"
    assert conso_r32_2[15].wrestler2.name == "Test34"
    winner_by_name("Test32", conso_r32_2[15])

    bracket_r16 = matches.reload.select { |m| m.bracket_position == "Bracket Round of 16" }.sort_by(&:bracket_position_number)
    assert bracket_r16[0].wrestler1.name == "Test1"
    assert bracket_r16[0].wrestler2.name == "Test17"
    winner_by_name("Test1", bracket_r16[0])
    assert bracket_r16[1].wrestler1.name == "Test24"
    assert bracket_r16[1].wrestler2.name == "Test8"
    winner_by_name("Test8", bracket_r16[1])
    assert bracket_r16[2].wrestler1.name == "Test5"
    assert bracket_r16[2].wrestler2.name == "Test21"
    winner_by_name("Test5", bracket_r16[2])
    assert bracket_r16[3].wrestler1.name == "Test13"
    assert bracket_r16[3].wrestler2.name == "Test4"
    winner_by_name("Test4", bracket_r16[3])
    assert bracket_r16[4].wrestler1.name == "Test3"
    assert bracket_r16[4].wrestler2.name == "Test19"
    winner_by_name("Test3", bracket_r16[4])
    assert bracket_r16[5].wrestler1.name == "Test11"
    assert bracket_r16[5].wrestler2.name == "Test27"
    winner_by_name("Test27", bracket_r16[5])
    assert bracket_r16[6].wrestler1.name == "Test7"
    assert bracket_r16[6].wrestler2.name == "Test23"
    winner_by_name("Test23", bracket_r16[6])
    assert bracket_r16[7].wrestler1.name == "Test15"
    assert bracket_r16[7].wrestler2.name == "Test2"
    winner_by_name("Test2", bracket_r16[7])

    quarters = matches.reload.select { |m| m.bracket_position == "Quarter" }.sort_by(&:bracket_position_number)
    assert_equal "Test1", quarters[0].reload.wrestler1.name
    assert_equal "Test8", quarters[0].reload.wrestler2.name
    assert_equal "Test5", quarters[1].reload.wrestler1.name
    assert_equal "Test4", quarters[1].reload.wrestler2.name
    assert_equal "Test3", quarters[2].reload.wrestler1.name
    assert_equal "Test27", quarters[2].reload.wrestler2.name
    assert_equal "Test23", quarters[3].reload.wrestler1.name
    assert_equal "Test2", quarters[3].reload.wrestler2.name
    winner_by_name("Test1", quarters[0])
    winner_by_name("Test5", quarters[1])
    winner_by_name("Test3", quarters[2])
    winner_by_name("Test2", quarters[3])

    conso_r16_1 = matches.reload.select { |m| m.bracket_position == "Conso Round of 16.1" }.sort_by(&:bracket_position_number)
    assert_equal "Test31", conso_r16_1[0].reload.wrestler1.name
    assert_equal "Test16", conso_r16_1[0].reload.wrestler2.name
    assert_equal "Test10", conso_r16_1[1].reload.wrestler1.name
    assert_equal "Test26", conso_r16_1[1].reload.wrestler2.name
    assert_equal "Test6",  conso_r16_1[2].reload.wrestler1.name
    assert_equal "Test22", conso_r16_1[2].reload.wrestler2.name
    assert_equal "Test45", conso_r16_1[3].reload.wrestler1.name
    assert_equal "Test30", conso_r16_1[3].reload.wrestler2.name
    assert_equal "Test35", conso_r16_1[4].reload.wrestler1.name
    assert_equal "Test20", conso_r16_1[4].reload.wrestler2.name
    assert_equal "Test43", conso_r16_1[5].reload.wrestler1.name
    assert_equal "Test59", conso_r16_1[5].reload.wrestler2.name
    assert_equal "Test25", conso_r16_1[6].reload.wrestler1.name
    assert_equal "Test9",  conso_r16_1[6].reload.wrestler2.name
    assert_equal "Test47", conso_r16_1[7].reload.wrestler1.name
    assert_equal "Test32", conso_r16_1[7].reload.wrestler2.name
    winner_by_name("Test16", conso_r16_1[0])
    winner_by_name("Test10", conso_r16_1[1])
    winner_by_name("Test6",  conso_r16_1[2])
    winner_by_name("Test30", conso_r16_1[3])
    winner_by_name("Test35", conso_r16_1[4])
    winner_by_name("Test43", conso_r16_1[5])
    winner_by_name("Test25", conso_r16_1[6])
    winner_by_name("Test32", conso_r16_1[7])

    conso_r16_2 = matches.reload.select { |m| m.bracket_position == "Conso Round of 16.2" }.sort_by(&:bracket_position_number)
    assert_equal "Test17", conso_r16_2[0].reload.wrestler1.name
    assert_equal "Test16", conso_r16_2[0].reload.wrestler2.name
    assert_equal "Test24", conso_r16_2[1].reload.wrestler1.name
    assert_equal "Test10", conso_r16_2[1].reload.wrestler2.name
    assert_equal "Test21", conso_r16_2[2].reload.wrestler1.name
    assert_equal "Test6",  conso_r16_2[2].reload.wrestler2.name
    assert_equal "Test13", conso_r16_2[3].reload.wrestler1.name
    assert_equal "Test30", conso_r16_2[3].reload.wrestler2.name
    assert_equal "Test19", conso_r16_2[4].reload.wrestler1.name
    assert_equal "Test35", conso_r16_2[4].reload.wrestler2.name
    assert_equal "Test11", conso_r16_2[5].reload.wrestler1.name
    assert_equal "Test43", conso_r16_2[5].reload.wrestler2.name
    assert_equal "Test7",  conso_r16_2[6].reload.wrestler1.name
    assert_equal "Test25", conso_r16_2[6].reload.wrestler2.name
    assert_equal "Test15", conso_r16_2[7].reload.wrestler1.name
    assert_equal "Test32", conso_r16_2[7].reload.wrestler2.name
    winner_by_name("Test16", conso_r16_2[0])
    winner_by_name("Test10", conso_r16_2[1])
    winner_by_name("Test6",  conso_r16_2[2])
    winner_by_name("Test30", conso_r16_2[3])
    winner_by_name("Test35", conso_r16_2[4])
    winner_by_name("Test43", conso_r16_2[5])
    winner_by_name("Test25", conso_r16_2[6])
    winner_by_name("Test32", conso_r16_2[7])

    conso_r8_1 = matches.reload.select { |m| m.bracket_position == "Conso Round of 8.1" }.sort_by(&:bracket_position_number)
    assert_equal "Test16", conso_r8_1[0].reload.wrestler1.name
    assert_equal "Test10", conso_r8_1[0].reload.wrestler2.name
    assert_equal "Test6",  conso_r8_1[1].reload.wrestler1.name
    assert_equal "Test30", conso_r8_1[1].reload.wrestler2.name
    assert_equal "Test35", conso_r8_1[2].reload.wrestler1.name
    assert_equal "Test43", conso_r8_1[2].reload.wrestler2.name
    assert_equal "Test25", conso_r8_1[3].reload.wrestler1.name
    assert_equal "Test32", conso_r8_1[3].reload.wrestler2.name
    winner_by_name("Test16", conso_r8_1[0])
    winner_by_name("Test6",  conso_r8_1[1])
    winner_by_name("Test35", conso_r8_1[2])
    winner_by_name("Test25", conso_r8_1[3])

    conso_r8_2 = matches.reload.select { |m| m.bracket_position == "Conso Round of 8.2" }.sort_by(&:bracket_position_number)
    assert_equal "Test23", conso_r8_2[0].reload.wrestler1.name
    assert_equal "Test16", conso_r8_2[0].reload.wrestler2.name
    assert_equal "Test27", conso_r8_2[1].reload.wrestler1.name
    assert_equal "Test6",  conso_r8_2[1].reload.wrestler2.name
    assert_equal "Test4",  conso_r8_2[2].reload.wrestler1.name
    assert_equal "Test35", conso_r8_2[2].reload.wrestler2.name
    assert_equal "Test8",  conso_r8_2[3].reload.wrestler1.name
    assert_equal "Test25", conso_r8_2[3].reload.wrestler2.name
    winner_by_name("Test16", conso_r8_2[0])
    winner_by_name("Test6",  conso_r8_2[1])
    winner_by_name("Test35", conso_r8_2[2])
    winner_by_name("Test25", conso_r8_2[3])

    conso_quarters = matches.reload.select { |m| m.bracket_position == "Conso Quarter" }.sort_by(&:bracket_position_number)
    assert conso_quarters.select { |m| m.bracket_position_number == 1 }.first.reload.wrestler1.name == "Test16"
    assert conso_quarters.select { |m| m.bracket_position_number == 1 }.first.reload.wrestler2.name == "Test6"
    winner_by_name("Test16", conso_quarters.select { |m| m.bracket_position_number == 1 }.first)
    assert conso_quarters.select { |m| m.bracket_position_number == 2 }.first.reload.wrestler1.name == "Test35"
    assert conso_quarters.select { |m| m.bracket_position_number == 2 }.first.reload.wrestler2.name == "Test25"
    winner_by_name("Test35", conso_quarters.select { |m| m.bracket_position_number == 2 }.first)

    semis = matches.reload.select { |m| m.bracket_position == "Semis" }.sort_by(&:bracket_position_number)
    assert_equal "Test1", semis[0].reload.wrestler1.name
    assert_equal "Test5", semis[0].reload.wrestler2.name
    assert_equal "Test3", semis[1].reload.wrestler1.name
    assert_equal "Test2", semis[1].reload.wrestler2.name
    winner_by_name("Test5", semis[0])
    winner_by_name("Test2", semis[1])

    semis_conso = matches.reload.select { |m| m.bracket_position == "Conso Semis" }.sort_by(&:bracket_position_number)
    bout0_names = [semis_conso[0].reload.wrestler1&.name, semis_conso[0].reload.wrestler2&.name]
    bout1_names = [semis_conso[1].reload.wrestler1&.name, semis_conso[1].reload.wrestler2&.name]
    assert (bout0_names & ["Test1","Test16"]).size == 2
    assert (bout1_names & ["Test3","Test35"]).size == 2
    winner_by_name("Test1", semis_conso[0])
    winner_by_name("Test3", semis_conso[1])

    # --- PLACEMENT MATCHES ---
    first_finals   = matches.reload.find { |m| m.bracket_position == "1/2" }
    third_finals   = matches.reload.find { |m| m.bracket_position == "3/4" }
    fifth_finals   = matches.reload.find { |m| m.bracket_position == "5/6" }
    seventh_finals = matches.reload.find { |m| m.bracket_position == "7/8" }

    # 1st/2nd: winners of semis
    assert_equal "Test5", first_finals.reload.wrestler1.name
    assert_equal "Test2", first_finals.reload.wrestler2.name

    # 3rd/4th: winners of Conso Semis (we set winners to champs losers 1 and 3)
    assert_equal "Test1", third_finals.reload.wrestler1.name
    assert_equal "Test3", third_finals.reload.wrestler2.name

    # 5th/6th: losers of Conso Semis (the CQ winners we defeated there)
    assert_equal "Test16", fifth_finals.reload.wrestler1.name
    assert_equal "Test35", fifth_finals.reload.wrestler2.name

    # 7th/8th: losers of Conso Quarters (the two who didn’t advance: 6 and 25)
    assert_equal "Test6",  seventh_finals.reload.wrestler1.name
    assert_equal "Test25", seventh_finals.reload.wrestler2.name

    # DEBUG
    # matches.sort_by{|m| m.bout_number}.each do |match|
    #   match.reload
    #   puts "Bracket Position: #{match.bracket_position} Round: #{match.round} #{match.w1_bracket_name} vs #{match.w2_bracket_name}"
    # end
  end
end