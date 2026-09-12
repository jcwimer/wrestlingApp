# frozen_string_literal: true

require 'test_helper'

class DoubleEliminationThirtyTwoManEightPlacesMatchGeneration < ActionDispatch::IntegrationTest
  def setup
    create_double_elim_tournament_single_weight(30, 'Regular Double Elimination 1-8')
  end

  test 'Match generation works' do
    assert @tournament.matches.count == 62
    assert @tournament.matches.count { |m| m.bracket_position == 'Bracket Round of 32' } == 16
    assert @tournament.matches.count { |m| m.bracket_position == 'Bracket Round of 16' } == 8
    assert @tournament.matches.count { |m| m.bracket_position == 'Conso Round of 16.1' } == 8
    assert @tournament.matches.count { |m| m.bracket_position == 'Conso Round of 16.2' } == 8
    assert @tournament.matches.count { |m| m.bracket_position == 'Conso Round of 8.1' } == 4
    assert @tournament.matches.count { |m| m.bracket_position == 'Conso Round of 8.2' } == 4
    assert(@tournament.matches.one? { |m| m.bracket_position == '1/2' })
    assert(@tournament.matches.one? { |m| m.bracket_position == '3/4' })
    assert(@tournament.matches.one? { |m| m.bracket_position == '5/6' })
    assert(@tournament.matches.one? { |m| m.bracket_position == '7/8' })
    assert @tournament.matches.count { |m| m.bracket_position == 'Quarter' } == 4
    assert @tournament.matches.count { |m| m.bracket_position == 'Semis' } == 2
    assert @tournament.matches.count { |m| m.bracket_position == 'Conso Quarter' } == 2
    assert @tournament.matches.count { |m| m.bracket_position == 'Conso Semis' } == 2
  end

  test 'Seeded wrestlers have correct first line' do
    @tournament.matches.reload
    match1 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 32' and match.bracket_position_number == 1 }
    match2 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 32' and match.bracket_position_number == 2 }
    match3 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 32' and match.bracket_position_number == 3 }
    match4 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 32' and match.bracket_position_number == 4 }
    match5 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 32' and match.bracket_position_number == 5 }
    match6 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 32' and match.bracket_position_number == 6 }
    match7 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 32' and match.bracket_position_number == 7 }
    match8 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 32' and match.bracket_position_number == 8 }
    match9 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 32' and match.bracket_position_number == 9 }
    match10 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 32' and match.bracket_position_number == 10 }
    match11 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 32' and match.bracket_position_number == 11 }
    match12 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 32' and match.bracket_position_number == 12 }
    match13 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 32' and match.bracket_position_number == 13 }
    match14 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 32' and match.bracket_position_number == 14 }
    match15 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 32' and match.bracket_position_number == 15 }
    match16 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 32' and match.bracket_position_number == 16 }

    assert match1.wrestler1.bracket_line == 1
    assert match1.loser2_name == 'BYE'

    assert match2.wrestler1.bracket_line == 16
    assert match2.wrestler2.bracket_line == 17

    assert match3.wrestler1.bracket_line == 9
    assert match3.wrestler2.bracket_line == 24

    assert match4.wrestler1.bracket_line == 8
    assert match4.wrestler2.bracket_line == 25

    assert match5.wrestler1.bracket_line == 5
    assert match5.wrestler2.bracket_line == 28

    assert match6.wrestler1.bracket_line == 12
    assert match6.wrestler2.bracket_line == 21

    assert match7.wrestler1.bracket_line == 13
    assert match7.wrestler2.bracket_line == 20

    assert match8.wrestler1.bracket_line == 4
    assert match8.wrestler2.bracket_line == 29

    assert match9.wrestler1.bracket_line == 3
    assert match9.wrestler2.bracket_line == 30

    assert match10.wrestler1.bracket_line == 14
    assert match10.wrestler2.bracket_line == 19

    assert match11.wrestler1.bracket_line == 11
    assert match11.wrestler2.bracket_line == 22

    assert match12.wrestler1.bracket_line == 6
    assert match12.wrestler2.bracket_line == 27

    assert match13.wrestler1.bracket_line == 7
    assert match13.wrestler2.bracket_line == 26

    assert match14.wrestler1.bracket_line == 10
    assert match14.wrestler2.bracket_line == 23

    assert match15.wrestler1.bracket_line == 15
    assert match15.wrestler2.bracket_line == 18

    assert match16.wrestler1.bracket_line == 2
    assert match16.loser2_name == 'BYE'
  end

  test 'Byes are advanced correctly' do
    @tournament.matches.reload
    match1 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 16' and match.bracket_position_number == 1 }
    match2 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 16' and match.bracket_position_number == 8 }

    assert match1.wrestler1.name == 'Test1'
    assert match2.wrestler2.name == 'Test2'
  end

  test 'Loser names set up correctly' do
    @tournament.matches.reload
    @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 32' and match.bracket_position_number == 1 }
    match2 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 32' and match.bracket_position_number == 2 }
    match3 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 32' and match.bracket_position_number == 3 }
    match4 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 32' and match.bracket_position_number == 4 }
    match5 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 32' and match.bracket_position_number == 5 }
    match6 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 32' and match.bracket_position_number == 6 }
    match7 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 32' and match.bracket_position_number == 7 }
    match8 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 32' and match.bracket_position_number == 8 }
    match9 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 32' and match.bracket_position_number == 9 }
    match10 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 32' and match.bracket_position_number == 10 }
    match11 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 32' and match.bracket_position_number == 11 }
    match12 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 32' and match.bracket_position_number == 12 }
    match13 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 32' and match.bracket_position_number == 13 }
    match14 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 32' and match.bracket_position_number == 14 }
    match15 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 32' and match.bracket_position_number == 15 }
    @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 32' and match.bracket_position_number == 16 }

    # Conso round of 16.1
    assert @tournament.matches.find { |m| m.bracket_position == 'Conso Round of 16.1' && m.bracket_position_number == 1 }.loser1_name == 'BYE'
    assert @tournament.matches.find { |m|
      m.bracket_position == 'Conso Round of 16.1' && m.bracket_position_number == 1
    }.loser2_name == "Loser of #{match2.bout_number}"
    assert @tournament.matches.find { |m|
      m.bracket_position == 'Conso Round of 16.1' && m.bracket_position_number == 2
    }.loser1_name == "Loser of #{match3.bout_number}"
    assert @tournament.matches.find { |m|
      m.bracket_position == 'Conso Round of 16.1' && m.bracket_position_number == 2
    }.loser2_name == "Loser of #{match4.bout_number}"
    assert @tournament.matches.find { |m|
      m.bracket_position == 'Conso Round of 16.1' && m.bracket_position_number == 3
    }.loser1_name == "Loser of #{match5.bout_number}"
    assert @tournament.matches.find { |m|
      m.bracket_position == 'Conso Round of 16.1' && m.bracket_position_number == 3
    }.loser2_name == "Loser of #{match6.bout_number}"
    assert @tournament.matches.find { |m|
      m.bracket_position == 'Conso Round of 16.1' && m.bracket_position_number == 4
    }.loser1_name == "Loser of #{match7.bout_number}"
    assert @tournament.matches.find { |m|
      m.bracket_position == 'Conso Round of 16.1' && m.bracket_position_number == 4
    }.loser2_name == "Loser of #{match8.bout_number}"
    assert @tournament.matches.find { |m|
      m.bracket_position == 'Conso Round of 16.1' && m.bracket_position_number == 5
    }.loser1_name == "Loser of #{match9.bout_number}"
    assert @tournament.matches.find { |m|
      m.bracket_position == 'Conso Round of 16.1' && m.bracket_position_number == 5
    }.loser2_name == "Loser of #{match10.bout_number}"
    assert @tournament.matches.find { |m|
      m.bracket_position == 'Conso Round of 16.1' && m.bracket_position_number == 6
    }.loser1_name == "Loser of #{match11.bout_number}"
    assert @tournament.matches.find { |m|
      m.bracket_position == 'Conso Round of 16.1' && m.bracket_position_number == 6
    }.loser2_name == "Loser of #{match12.bout_number}"
    assert @tournament.matches.find { |m|
      m.bracket_position == 'Conso Round of 16.1' && m.bracket_position_number == 7
    }.loser1_name == "Loser of #{match13.bout_number}"
    assert @tournament.matches.find { |m|
      m.bracket_position == 'Conso Round of 16.1' && m.bracket_position_number == 7
    }.loser2_name == "Loser of #{match14.bout_number}"
    assert @tournament.matches.find { |m|
      m.bracket_position == 'Conso Round of 16.1' && m.bracket_position_number == 8
    }.loser1_name == "Loser of #{match15.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == 'Conso Round of 16.1' && m.bracket_position_number == 8 }.loser2_name == 'BYE'

    # Conso round of 16.2 cross bracketed
    bracket_r16_match1 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 16' and match.bracket_position_number == 1 }
    bracket_r16_match2 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 16' and match.bracket_position_number == 2 }
    bracket_r16_match3 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 16' and match.bracket_position_number == 3 }
    bracket_r16_match4 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 16' and match.bracket_position_number == 4 }
    bracket_r16_match5 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 16' and match.bracket_position_number == 5 }
    bracket_r16_match6 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 16' and match.bracket_position_number == 6 }
    bracket_r16_match7 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 16' and match.bracket_position_number == 7 }
    bracket_r16_match8 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 16' and match.bracket_position_number == 8 }
    assert @tournament.matches.find { |m|
      m.bracket_position == 'Conso Round of 16.2' && m.bracket_position_number == 1
    }.loser1_name == "Loser of #{bracket_r16_match8.bout_number}"
    assert @tournament.matches.find { |m|
      m.bracket_position == 'Conso Round of 16.2' && m.bracket_position_number == 2
    }.loser1_name == "Loser of #{bracket_r16_match7.bout_number}"
    assert @tournament.matches.find { |m|
      m.bracket_position == 'Conso Round of 16.2' && m.bracket_position_number == 3
    }.loser1_name == "Loser of #{bracket_r16_match6.bout_number}"
    assert @tournament.matches.find { |m|
      m.bracket_position == 'Conso Round of 16.2' && m.bracket_position_number == 4
    }.loser1_name == "Loser of #{bracket_r16_match5.bout_number}"
    assert @tournament.matches.find { |m|
      m.bracket_position == 'Conso Round of 16.2' && m.bracket_position_number == 5
    }.loser1_name == "Loser of #{bracket_r16_match4.bout_number}"
    assert @tournament.matches.find { |m|
      m.bracket_position == 'Conso Round of 16.2' && m.bracket_position_number == 6
    }.loser1_name == "Loser of #{bracket_r16_match3.bout_number}"
    assert @tournament.matches.find { |m|
      m.bracket_position == 'Conso Round of 16.2' && m.bracket_position_number == 7
    }.loser1_name == "Loser of #{bracket_r16_match2.bout_number}"
    assert @tournament.matches.find { |m|
      m.bracket_position == 'Conso Round of 16.2' && m.bracket_position_number == 8
    }.loser1_name == "Loser of #{bracket_r16_match1.bout_number}"

    # Conso round of 8.2
    quarter1 = @tournament.matches.find { |match| match.bracket_position == 'Quarter' and match.bracket_position_number == 1 }
    quarter2 = @tournament.matches.find { |match| match.bracket_position == 'Quarter' and match.bracket_position_number == 2 }
    quarter3 = @tournament.matches.find { |match| match.bracket_position == 'Quarter' and match.bracket_position_number == 3 }
    quarter4 = @tournament.matches.find { |match| match.bracket_position == 'Quarter' and match.bracket_position_number == 4 }
    conso_r8_2_match1 = @tournament.matches.find { |match| match.bracket_position == 'Conso Round of 8.2' && match.bracket_position_number == 1 }
    conso_r8_2_match2 = @tournament.matches.find { |match| match.bracket_position == 'Conso Round of 8.2' && match.bracket_position_number == 2 }
    conso_r8_2_match3 = @tournament.matches.find { |match| match.bracket_position == 'Conso Round of 8.2' && match.bracket_position_number == 3 }
    conso_r8_2_match4 = @tournament.matches.find { |match| match.bracket_position == 'Conso Round of 8.2' && match.bracket_position_number == 4 }
    assert conso_r8_2_match1.loser1_name == "Loser of #{quarter1.bout_number}"
    assert conso_r8_2_match2.loser1_name == "Loser of #{quarter2.bout_number}"
    assert conso_r8_2_match3.loser1_name == "Loser of #{quarter3.bout_number}"
    assert conso_r8_2_match4.loser1_name == "Loser of #{quarter4.bout_number}"

    # Conso Semis
    semis1 = @tournament.matches.find { |match| match.bracket_position == 'Semis' and match.bracket_position_number == 1 }
    semis2 = @tournament.matches.find { |match| match.bracket_position == 'Semis' and match.bracket_position_number == 2 }
    consosemis1 = @tournament.matches.find { |match| match.bracket_position == 'Conso Semis' and match.bracket_position_number == 1 }
    consosemis2 = @tournament.matches.find { |match| match.bracket_position == 'Conso Semis' and match.bracket_position_number == 2 }
    assert consosemis1.loser1_name == "Loser of #{semis2.bout_number}"
    assert consosemis2.loser1_name == "Loser of #{semis1.bout_number}"

    # 5/6
    assert @tournament.matches.find { |m|
      m.bracket_position == '5/6' && m.bracket_position_number == 1
    }.loser1_name == "Loser of #{consosemis1.bout_number}"
    assert @tournament.matches.find { |m|
      m.bracket_position == '5/6' && m.bracket_position_number == 1
    }.loser2_name == "Loser of #{consosemis2.bout_number}"

    # 7/8
    consoquarters1 = @tournament.matches.find { |match| match.bracket_position == 'Conso Quarter' and match.bracket_position_number == 1 }
    consoquarters2 = @tournament.matches.find { |match| match.bracket_position == 'Conso Quarter' and match.bracket_position_number == 2 }
    assert @tournament.matches.find { |m|
      m.bracket_position == '7/8' && m.bracket_position_number == 1
    }.loser1_name == "Loser of #{consoquarters1.bout_number}"
    assert @tournament.matches.find { |m|
      m.bracket_position == '7/8' && m.bracket_position_number == 1
    }.loser2_name == "Loser of #{consoquarters2.bout_number}"
  end

  test 'Placement points are given when moving through bracket' do
    match = @tournament.matches.find { |m| m.bracket_position == 'Semis' }
    wrestler = get_wrestler_by_name('Test1')
    match.w1 = wrestler.id
    match.save

    match2 = @tournament.matches.find { |m| m.bracket_position == 'Conso Semis' }
    wrestler2 = get_wrestler_by_name('Test2')
    match2.w1 = wrestler2.id
    match2.save

    match3 = @tournament.matches.find { |m| m.bracket_position == 'Conso Quarter' }
    wrestler3 = get_wrestler_by_name('Test3')
    match3.w1 = wrestler3.id
    match3.save

    assert wrestler.reload.placement_points == 3
    assert wrestler2.reload.placement_points == 3
    assert wrestler3.reload.placement_points == 1
  end

  # test "Run through all matches works" do
  #   @tournament.matches.sort_by{ |match| match.bout_number }.each do |match|
  #     match.reload
  #     if match.finished != 1 and match.w1 and match.w2
  #         match.winner_id = match.w1
  #         match.win_type = "Decision"
  #         match.score = "0-0"
  #         match.finished = 1
  #         match.save
  #     end
  #   end
  #   assert @tournament.matches.reload.select{|m| m.finished == 0}.count == 0
  # end
end
