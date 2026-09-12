# frozen_string_literal: true

require 'test_helper'

class ModifiedDoubleEliminationEightPlacesManMatchGeneration < ActionDispatch::IntegrationTest
  def setup
    create_double_elim_tournament_single_weight(14, 'Modified 16 Man Double Elimination 1-8')
  end

  test 'Match generation works' do
    assert @tournament.matches.count == 28
    assert(@tournament.matches.one? { |m| m.bracket_position == '1/2' })
    assert(@tournament.matches.one? { |m| m.bracket_position == '3/4' })
    assert(@tournament.matches.one? { |m| m.bracket_position == '5/6' })
    assert(@tournament.matches.one? { |m| m.bracket_position == '7/8' })
    assert @tournament.matches.count { |m| m.bracket_position == 'Bracket Round of 16' and m.round == 1 } == 8
    assert @tournament.matches.count { |m| m.bracket_position == 'Quarter' } == 4
    assert @tournament.matches.count { |m| m.bracket_position == 'Semis' } == 2
    assert @tournament.matches.count { |m| m.bracket_position == 'Conso Round of 8' and m.round == 2 } == 4
    assert @tournament.matches.count { |m| m.bracket_position == 'Conso Quarter' } == 4
    assert @tournament.matches.count { |m| m.bracket_position == 'Conso Semis' } == 2
  end

  test 'Seeded wrestlers have correct first line' do
    @tournament.matches.reload
    match1 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 16' and match.bracket_position_number == 1 }
    match2 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 16' and match.bracket_position_number == 2 }
    match3 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 16' and match.bracket_position_number == 3 }
    match4 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 16' and match.bracket_position_number == 4 }
    match5 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 16' and match.bracket_position_number == 5 }
    match6 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 16' and match.bracket_position_number == 6 }
    match7 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 16' and match.bracket_position_number == 7 }
    match8 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 16' and match.bracket_position_number == 8 }

    assert match1.wrestler1.bracket_line == 1
    assert match1.loser2_name == 'BYE'

    assert match2.wrestler1.bracket_line == 8
    assert match2.wrestler2.bracket_line == 9

    assert match3.wrestler1.bracket_line == 5
    assert match3.wrestler2.bracket_line == 12

    assert match4.wrestler1.bracket_line == 4
    assert match4.wrestler2.bracket_line == 14

    assert match5.wrestler1.bracket_line == 3
    assert match5.wrestler2.bracket_line == 13

    assert match6.wrestler1.bracket_line == 6
    assert match6.wrestler2.bracket_line == 11

    assert match7.wrestler1.bracket_line == 7
    assert match7.wrestler2.bracket_line == 10

    assert match8.wrestler1.bracket_line == 2
    assert match8.loser2_name == 'BYE'
  end

  test 'Byes are advanced correctly' do
    @tournament.matches.reload
    match1 = @tournament.matches.find { |match| match.round == 2 and match.bracket_position == 'Quarter' and match.bracket_position_number == 1 }
    match2 = @tournament.matches.find { |match| match.round == 2 and match.bracket_position == 'Quarter' and match.bracket_position_number == 4 }

    assert match1.wrestler1.name == 'Test1'
    assert match2.wrestler2.name == 'Test2'
  end

  test 'Loser names set up correctly' do
    @tournament.matches.reload
    @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 16' and match.bracket_position_number == 1 }
    match2 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 16' and match.bracket_position_number == 2 }
    match3 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 16' and match.bracket_position_number == 3 }
    match4 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 16' and match.bracket_position_number == 4 }
    match5 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 16' and match.bracket_position_number == 5 }
    match6 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 16' and match.bracket_position_number == 6 }
    match7 = @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 16' and match.bracket_position_number == 7 }
    @tournament.matches.find { |match| match.bracket_position == 'Bracket Round of 16' and match.bracket_position_number == 8 }

    assert @tournament.matches.find { |m| m.bracket_position == 'Conso Round of 8' && m.bracket_position_number == 1 }.loser1_name == 'BYE'
    assert @tournament.matches.find { |m|
      m.bracket_position == 'Conso Round of 8' && m.bracket_position_number == 1
    }.loser2_name == "Loser of #{match2.bout_number}"
    assert @tournament.matches.find { |m|
      m.bracket_position == 'Conso Round of 8' && m.bracket_position_number == 2
    }.loser1_name == "Loser of #{match3.bout_number}"
    assert @tournament.matches.find { |m|
      m.bracket_position == 'Conso Round of 8' && m.bracket_position_number == 2
    }.loser2_name == "Loser of #{match4.bout_number}"
    assert @tournament.matches.find { |m|
      m.bracket_position == 'Conso Round of 8' && m.bracket_position_number == 3
    }.loser1_name == "Loser of #{match5.bout_number}"
    assert @tournament.matches.find { |m|
      m.bracket_position == 'Conso Round of 8' && m.bracket_position_number == 3
    }.loser2_name == "Loser of #{match6.bout_number}"
    assert @tournament.matches.find { |m|
      m.bracket_position == 'Conso Round of 8' && m.bracket_position_number == 4
    }.loser1_name == "Loser of #{match7.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == 'Conso Round of 8' && m.bracket_position_number == 4 }.loser2_name == 'BYE'

    quarter1 = @tournament.matches.find { |match| match.bracket_position == 'Quarter' and match.bracket_position_number == 1 }
    quarter2 = @tournament.matches.find { |match| match.bracket_position == 'Quarter' and match.bracket_position_number == 2 }
    quarter3 = @tournament.matches.find { |match| match.bracket_position == 'Quarter' and match.bracket_position_number == 3 }
    quarter4 = @tournament.matches.find { |match| match.bracket_position == 'Quarter' and match.bracket_position_number == 4 }
    consoround2match1 = @tournament.matches.find do |match|
      match.bracket_position == 'Conso Quarter' and match.round == 3 && match.bracket_position_number == 1
    end
    consoround2match2 = @tournament.matches.find do |match|
      match.bracket_position == 'Conso Quarter' and match.round == 3 && match.bracket_position_number == 2
    end
    consoround2match3 = @tournament.matches.find do |match|
      match.bracket_position == 'Conso Quarter' and match.round == 3 && match.bracket_position_number == 3
    end
    consoround2match4 = @tournament.matches.find do |match|
      match.bracket_position == 'Conso Quarter' and match.round == 3 && match.bracket_position_number == 4
    end

    assert consoround2match1.loser1_name == "Loser of #{quarter4.bout_number}"
    assert consoround2match2.loser1_name == "Loser of #{quarter3.bout_number}"
    assert consoround2match3.loser1_name == "Loser of #{quarter2.bout_number}"
    assert consoround2match4.loser1_name == "Loser of #{quarter1.bout_number}"

    semis1 = @tournament.matches.find { |match| match.bracket_position == 'Semis' and match.bracket_position_number == 1 }
    semis2 = @tournament.matches.find { |match| match.bracket_position == 'Semis' and match.bracket_position_number == 2 }

    assert @tournament.matches.find { |m| m.bracket_position == '3/4' && m.bracket_position_number == 1 }.loser1_name == "Loser of #{semis1.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == '3/4' && m.bracket_position_number == 1 }.loser2_name == "Loser of #{semis2.bout_number}"

    consosemis1 = @tournament.matches.find { |match| match.bracket_position == 'Conso Semis' and match.bracket_position_number == 1 }
    consosemis2 = @tournament.matches.find { |match| match.bracket_position == 'Conso Semis' and match.bracket_position_number == 2 }

    assert @tournament.matches.find { |m|
      m.bracket_position == '7/8' && m.bracket_position_number == 1
    }.loser1_name == "Loser of #{consosemis1.bout_number}"
    assert @tournament.matches.find { |m|
      m.bracket_position == '7/8' && m.bracket_position_number == 1
    }.loser2_name == "Loser of #{consosemis2.bout_number}"
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

    assert wrestler.reload.placement_points == 7
    assert wrestler2.reload.placement_points == 1
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
