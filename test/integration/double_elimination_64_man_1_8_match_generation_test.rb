require 'test_helper'

class DoubleEliminationSixtyFourManEightPlacesMatchGeneration < ActionDispatch::IntegrationTest
  def setup
    # Create a 64‐slot double‐elimination bracket with 62 actual wrestlers (two byes for seeds 1 and 2)
    create_double_elim_tournament_single_weight(62, "Regular Double Elimination 1-8")
  end

  test "Match generation works for 64‐slot bracket" do
    assert @tournament.matches.count == 126

    # Winners‐bracket
    assert @tournament.matches.select { |m| m.bracket_position == "Bracket Round of 64" }.count == 32
    assert @tournament.matches.select { |m| m.bracket_position == "Bracket Round of 32" }.count == 16
    assert @tournament.matches.select { |m| m.bracket_position == "Bracket Round of 16" }.count == 8
    assert @tournament.matches.select { |m| m.bracket_position == "Quarter" }.count == 4
    assert @tournament.matches.select { |m| m.bracket_position == "Semis" }.count == 2
    assert @tournament.matches.select { |m| m.bracket_position == "1/2" }.count == 1

    # Losers‐bracket
    assert @tournament.matches.select { |m| m.bracket_position == "Conso Round of 32.1" }.count == 16
    assert @tournament.matches.select { |m| m.bracket_position == "Conso Round of 32.2" }.count == 16
    assert @tournament.matches.select { |m| m.bracket_position == "Conso Round of 16.1" }.count == 8
    assert @tournament.matches.select { |m| m.bracket_position == "Conso Round of 16.2" }.count == 8
    assert @tournament.matches.select { |m| m.bracket_position == "Conso Round of 8.1" }.count == 4
    assert @tournament.matches.select { |m| m.bracket_position == "Conso Round of 8.2" }.count == 4
    assert @tournament.matches.select { |m| m.bracket_position == "Conso Quarter" }.count == 2
    assert @tournament.matches.select { |m| m.bracket_position == "Conso Semis" }.count == 2
    assert @tournament.matches.select { |m| m.bracket_position == "3/4" }.count == 1
    assert @tournament.matches.select { |m| m.bracket_position == "5/6" }.count == 1
    assert @tournament.matches.select { |m| m.bracket_position == "7/8" }.count == 1
  end

     test "Seeded wrestlers have correct first line in Round of 64" do
    @tournament.matches.reload

    # Collect the 32 "Bracket Round of 64" matches in bracket_position_number order
    matches_r64 = (1..32).map do |i|
      @tournament.matches.find { |m|
        m.bracket_position == "Bracket Round of 64" &&
        m.bracket_position_number == i
      }
    end

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
  end

  test "Byes are advanced correctly into Round of 32" do
    @tournament.matches.reload

    # Round of 32, match 1: seed 1 (bye) should be advanced
    match_r32_1  = @tournament.matches.find { |m|
      m.bracket_position == "Bracket Round of 32" && m.bracket_position_number == 1
    }
    assert match_r32_1.wrestler1.name == "Test1"

    # Round of 32, match 15: seed 2 (bye) should land in slot 2 of match 15
    match_r32_15 = @tournament.matches.find { |m|
      m.bracket_position == "Bracket Round of 32" && m.bracket_position_number == 16
    }
    assert match_r32_15.wrestler2.name == "Test2"
  end

   test "Loser names set up correctly" do
    @tournament.matches.reload

    # Round of 64 matches
    match1  = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 64" && m.bracket_position_number == 1  }
    match2  = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 64" && m.bracket_position_number == 2  }
    match3  = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 64" && m.bracket_position_number == 3  }
    match4  = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 64" && m.bracket_position_number == 4  }
    match5  = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 64" && m.bracket_position_number == 5  }
    match6  = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 64" && m.bracket_position_number == 6  }
    match7  = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 64" && m.bracket_position_number == 7  }
    match8  = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 64" && m.bracket_position_number == 8  }
    match9  = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 64" && m.bracket_position_number == 9  }
    match10 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 64" && m.bracket_position_number == 10 }
    match11 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 64" && m.bracket_position_number == 11 }
    match12 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 64" && m.bracket_position_number == 12 }
    match13 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 64" && m.bracket_position_number == 13 }
    match14 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 64" && m.bracket_position_number == 14 }
    match15 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 64" && m.bracket_position_number == 15 }
    match16 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 64" && m.bracket_position_number == 16 }
    match17 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 64" && m.bracket_position_number == 17 }
    match18 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 64" && m.bracket_position_number == 18 }
    match19 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 64" && m.bracket_position_number == 19 }
    match20 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 64" && m.bracket_position_number == 20 }
    match21 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 64" && m.bracket_position_number == 21 }
    match22 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 64" && m.bracket_position_number == 22 }
    match23 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 64" && m.bracket_position_number == 23 }
    match24 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 64" && m.bracket_position_number == 24 }
    match25 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 64" && m.bracket_position_number == 25 }
    match26 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 64" && m.bracket_position_number == 26 }
    match27 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 64" && m.bracket_position_number == 27 }
    match28 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 64" && m.bracket_position_number == 28 }
    match29 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 64" && m.bracket_position_number == 29 }
    match30 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 64" && m.bracket_position_number == 30 }
    match31 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 64" && m.bracket_position_number == 31 }
    match32 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 64" && m.bracket_position_number == 32 }

    # Conso Round of 32.1
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.1" && m.bracket_position_number == 1  }.loser1_name == "BYE"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.1" && m.bracket_position_number == 1  }.loser2_name == "Loser of #{match2.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.1" && m.bracket_position_number == 2  }.loser1_name == "Loser of #{match3.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.1" && m.bracket_position_number == 2  }.loser2_name == "Loser of #{match4.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.1" && m.bracket_position_number == 3  }.loser1_name == "Loser of #{match5.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.1" && m.bracket_position_number == 3  }.loser2_name == "Loser of #{match6.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.1" && m.bracket_position_number == 4  }.loser1_name == "Loser of #{match7.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.1" && m.bracket_position_number == 4  }.loser2_name == "Loser of #{match8.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.1" && m.bracket_position_number == 5  }.loser1_name == "Loser of #{match9.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.1" && m.bracket_position_number == 5  }.loser2_name == "Loser of #{match10.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.1" && m.bracket_position_number == 6  }.loser1_name == "Loser of #{match11.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.1" && m.bracket_position_number == 6  }.loser2_name == "Loser of #{match12.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.1" && m.bracket_position_number == 7  }.loser1_name == "Loser of #{match13.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.1" && m.bracket_position_number == 7  }.loser2_name == "Loser of #{match14.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.1" && m.bracket_position_number == 8  }.loser1_name == "Loser of #{match15.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.1" && m.bracket_position_number == 8  }.loser2_name == "Loser of #{match16.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.1" && m.bracket_position_number == 9  }.loser1_name == "Loser of #{match17.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.1" && m.bracket_position_number == 9  }.loser2_name == "Loser of #{match18.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.1" && m.bracket_position_number == 10 }.loser1_name == "Loser of #{match19.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.1" && m.bracket_position_number == 10 }.loser2_name == "Loser of #{match20.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.1" && m.bracket_position_number == 11 }.loser1_name == "Loser of #{match21.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.1" && m.bracket_position_number == 11 }.loser2_name == "Loser of #{match22.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.1" && m.bracket_position_number == 12 }.loser1_name == "Loser of #{match23.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.1" && m.bracket_position_number == 12 }.loser2_name == "Loser of #{match24.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.1" && m.bracket_position_number == 13 }.loser1_name == "Loser of #{match25.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.1" && m.bracket_position_number == 13 }.loser2_name == "Loser of #{match26.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.1" && m.bracket_position_number == 14 }.loser1_name == "Loser of #{match27.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.1" && m.bracket_position_number == 14 }.loser2_name == "Loser of #{match28.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.1" && m.bracket_position_number == 15 }.loser1_name == "Loser of #{match29.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.1" && m.bracket_position_number == 15 }.loser2_name == "Loser of #{match30.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.1" && m.bracket_position_number == 16 }.loser1_name == "Loser of #{match31.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.1" && m.bracket_position_number == 16 }.loser2_name == "BYE"

    # Conso Round of 32.2
    r32_match1  = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 32" && m.bracket_position_number == 1  }
    r32_match2  = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 32" && m.bracket_position_number == 2  }
    r32_match3  = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 32" && m.bracket_position_number == 3  }
    r32_match4  = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 32" && m.bracket_position_number == 4  }
    r32_match5  = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 32" && m.bracket_position_number == 5  }
    r32_match6  = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 32" && m.bracket_position_number == 6  }
    r32_match7  = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 32" && m.bracket_position_number == 7  }
    r32_match8  = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 32" && m.bracket_position_number == 8  }
    r32_match9  = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 32" && m.bracket_position_number == 9  }
    r32_match10 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 32" && m.bracket_position_number == 10 }
    r32_match11 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 32" && m.bracket_position_number == 11 }
    r32_match12 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 32" && m.bracket_position_number == 12 }
    r32_match13 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 32" && m.bracket_position_number == 13 }
    r32_match14 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 32" && m.bracket_position_number == 14 }
    r32_match15 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 32" && m.bracket_position_number == 15 }
    r32_match16 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 32" && m.bracket_position_number == 16 }

    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.2" && m.bracket_position_number == 1  }.loser1_name == "Loser of #{r32_match16.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.2" && m.bracket_position_number == 2  }.loser1_name == "Loser of #{r32_match15.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.2" && m.bracket_position_number == 3  }.loser1_name == "Loser of #{r32_match14.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.2" && m.bracket_position_number == 4  }.loser1_name == "Loser of #{r32_match13.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.2" && m.bracket_position_number == 5  }.loser1_name == "Loser of #{r32_match12.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.2" && m.bracket_position_number == 6  }.loser1_name == "Loser of #{r32_match11.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.2" && m.bracket_position_number == 7  }.loser1_name == "Loser of #{r32_match10.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.2" && m.bracket_position_number == 8  }.loser1_name == "Loser of #{r32_match9.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.2" && m.bracket_position_number == 9  }.loser1_name == "Loser of #{r32_match8.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.2" && m.bracket_position_number == 10 }.loser1_name == "Loser of #{r32_match7.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.2" && m.bracket_position_number == 11 }.loser1_name == "Loser of #{r32_match6.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.2" && m.bracket_position_number == 12 }.loser1_name == "Loser of #{r32_match5.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.2" && m.bracket_position_number == 13 }.loser1_name == "Loser of #{r32_match4.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.2" && m.bracket_position_number == 14 }.loser1_name == "Loser of #{r32_match3.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.2" && m.bracket_position_number == 15 }.loser1_name == "Loser of #{r32_match2.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 32.2" && m.bracket_position_number == 16 }.loser1_name == "Loser of #{r32_match1.bout_number}"

    # Conso Round of 16.2
    r16_match1 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 16" && m.bracket_position_number == 1 }
    r16_match2 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 16" && m.bracket_position_number == 2 }
    r16_match3 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 16" && m.bracket_position_number == 3 }
    r16_match4 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 16" && m.bracket_position_number == 4 }
    r16_match5 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 16" && m.bracket_position_number == 5 }
    r16_match6 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 16" && m.bracket_position_number == 6 }
    r16_match7 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 16" && m.bracket_position_number == 7 }
    r16_match8 = @tournament.matches.find { |m| m.bracket_position == "Bracket Round of 16" && m.bracket_position_number == 8 }

    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 16.2" && m.bracket_position_number == 1 }.loser1_name == "Loser of #{r16_match1.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 16.2" && m.bracket_position_number == 2 }.loser1_name == "Loser of #{r16_match2.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 16.2" && m.bracket_position_number == 3 }.loser1_name == "Loser of #{r16_match3.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 16.2" && m.bracket_position_number == 4 }.loser1_name == "Loser of #{r16_match4.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 16.2" && m.bracket_position_number == 5 }.loser1_name == "Loser of #{r16_match5.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 16.2" && m.bracket_position_number == 6 }.loser1_name == "Loser of #{r16_match6.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 16.2" && m.bracket_position_number == 7 }.loser1_name == "Loser of #{r16_match7.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 16.2" && m.bracket_position_number == 8 }.loser1_name == "Loser of #{r16_match8.bout_number}"

    # Conso Round of 8.2
    quarter1 = @tournament.matches.find { |m| m.bracket_position == "Quarter" && m.bracket_position_number == 1 }
    quarter2 = @tournament.matches.find { |m| m.bracket_position == "Quarter" && m.bracket_position_number == 2 }
    quarter3 = @tournament.matches.find { |m| m.bracket_position == "Quarter" && m.bracket_position_number == 3 }
    quarter4 = @tournament.matches.find { |m| m.bracket_position == "Quarter" && m.bracket_position_number == 4 }

    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 8.2" && m.bracket_position_number == 1 }.loser1_name == "Loser of #{quarter4.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 8.2" && m.bracket_position_number == 2 }.loser1_name == "Loser of #{quarter3.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 8.2" && m.bracket_position_number == 3 }.loser1_name == "Loser of #{quarter2.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == "Conso Round of 8.2" && m.bracket_position_number == 4 }.loser1_name == "Loser of #{quarter1.bout_number}"

    # Conso Semis
    semis1    = @tournament.matches.find { |m| m.bracket_position == "Semis" && m.bracket_position_number == 1 }
    semis2    = @tournament.matches.find { |m| m.bracket_position == "Semis" && m.bracket_position_number == 2 }
    conso_s1  = @tournament.matches.find { |m| m.bracket_position == "Conso Semis" && m.bracket_position_number == 1 }
    conso_s2  = @tournament.matches.find { |m| m.bracket_position == "Conso Semis" && m.bracket_position_number == 2 }

    assert conso_s1.loser1_name == "Loser of #{semis1.bout_number}"
    assert conso_s2.loser1_name == "Loser of #{semis2.bout_number}"

    # 5/6
    match_5_6 = @tournament.matches.find { |m| m.bracket_position == "5/6" && m.bracket_position_number == 1 }
    assert match_5_6.loser1_name == "Loser of #{conso_s1.bout_number}"
    assert match_5_6.loser2_name == "Loser of #{conso_s2.bout_number}"

    # 7/8
    cq1       = @tournament.matches.find { |m| m.bracket_position == "Conso Quarter" && m.bracket_position_number == 1 }
    cq2       = @tournament.matches.find { |m| m.bracket_position == "Conso Quarter" && m.bracket_position_number == 2 }
    match_7_8 = @tournament.matches.find { |m| m.bracket_position == "7/8" && m.bracket_position_number == 1 }

    assert match_7_8.loser1_name == "Loser of #{cq1.bout_number}"
    assert match_7_8.loser2_name == "Loser of #{cq2.bout_number}"
  end

  test "Placement points are given when moving through bracket" do
    match_semis      = @tournament.matches.find { |m|
      m.bracket_position == "Semis" && m.bracket_position_number == 1
    }
    wrestler_a       = get_wrestler_by_name("Test1")
    match_semis.w1   = wrestler_a.id
    match_semis.save

    match_conso_semi = @tournament.matches.find { |m|
      m.bracket_position == "Conso Semis" && m.bracket_position_number == 1
    }
    wrestler_b       = get_wrestler_by_name("Test2")
    match_conso_semi.w1 = wrestler_b.id
    match_conso_semi.save

    match_conso_q    = @tournament.matches.find { |m|
      m.bracket_position == "Conso Quarter" && m.bracket_position_number == 1
    }
    wrestler_c       = get_wrestler_by_name("Test3")
    match_conso_q.w1 = wrestler_c.id
    match_conso_q.save

    assert wrestler_a.reload.placement_points == 3
    assert wrestler_b.reload.placement_points == 3
    assert wrestler_c.reload.placement_points == 1
  end

  # test "Run through all matches works" do
  #   @tournament.matches.sort_by(&:bout_number).each do |match|
  #     match.reload
  #     if match.finished != 1 && match.w1 && match.w2
  #       match.winner_id = match.w1
  #       match.win_type  = "Decision"
  #       match.score     = "0-0"
  #       match.finished  = 1
  #       match.save
  #     end
  #   end

  #   assert @tournament.matches.reload.none? { |m| m.finished == 0 }
  # end

#   test "test output" do
#     matches_r64 = (1..32).map do |i|
#       @tournament.matches.find { |m|
#         m.bracket_position == "Bracket Round of 64" &&
#         m.bracket_position_number == i
#       }
#     end
#     matches_r64.sort_by{|m| m.bracket_position_number}.each do |match|
#         string = ""
#         if match.wrestler1
#             string += "#{match.wrestler1.bracket_line}"
#         end
#         string += " vs "
#         if match.wrestler2
#             string += "#{match.wrestler2.bracket_line}"
#         end
#         puts string
#     end
#   end
end
