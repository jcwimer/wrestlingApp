# frozen_string_literal: true

require 'test_helper'

class DoubleEliminationEightManMatchGeneration < ActionDispatch::IntegrationTest
  def setup
    create_double_elim_tournament_single_weight_1_6(6)
  end

  test 'Match generation works' do
    assert @tournament.matches.count == 13
    assert(@tournament.matches.one? { |m| m.bracket_position == '1/2' })
    assert(@tournament.matches.one? { |m| m.bracket_position == '3/4' })
    assert(@tournament.matches.one? { |m| m.bracket_position == '5/6' })
    assert @tournament.matches.count { |m| m.bracket_position == 'Quarter' } == 4
    assert @tournament.matches.count { |m| m.bracket_position == 'Semis' } == 2
    assert @tournament.matches.count { |m| m.bracket_position == 'Conso Quarter' } == 2
    assert @tournament.matches.count { |m| m.bracket_position == 'Conso Semis' } == 2
  end

  test 'Seeded wrestlers have correct first line' do
    @tournament.matches.reload
    match1 = @tournament.matches.find { |match| match.round == 1 and match.bracket_position_number == 1 }
    match2 = @tournament.matches.find { |match| match.round == 1 and match.bracket_position_number == 2 }
    match3 = @tournament.matches.find { |match| match.round == 1 and match.bracket_position_number == 3 }
    match4 = @tournament.matches.find { |match| match.round == 1 and match.bracket_position_number == 4 }

    assert match1.wrestler1.bracket_line == 1
    assert match1.loser2_name == 'BYE'

    assert match2.wrestler1.bracket_line == 4
    assert match2.wrestler2.bracket_line == 5

    assert match3.wrestler1.bracket_line == 3
    assert match3.wrestler2.bracket_line == 6

    assert match4.wrestler1.bracket_line == 2
    assert match4.loser2_name == 'BYE'
  end

  test 'Byes are advanced correctly' do
    @tournament.matches.reload
    match1 = @tournament.matches.find { |match| match.round == 2 and match.bracket_position == 'Semis' and match.bracket_position_number == 1 }
    match2 = @tournament.matches.find { |match| match.round == 2 and match.bracket_position == 'Semis' and match.bracket_position_number == 2 }

    assert match1.wrestler1.name == 'Test1'
    assert match2.wrestler2.name == 'Test2'
  end

  test 'Loser names set up correctly' do
    @tournament.matches.reload
    @tournament.matches.find { |match| match.round == 1 and match.bracket_position_number == 1 }
    match2 = @tournament.matches.find { |match| match.round == 1 and match.bracket_position_number == 2 }
    match3 = @tournament.matches.find { |match| match.round == 1 and match.bracket_position_number == 3 }
    @tournament.matches.find { |match| match.round == 1 and match.bracket_position_number == 4 }

    assert @tournament.matches.find { |m| m.bracket_position == 'Conso Quarter' && m.bracket_position_number == 1 }.loser1_name == 'BYE'
    assert @tournament.matches.find { |m|
      m.bracket_position == 'Conso Quarter' && m.bracket_position_number == 1
    }.loser2_name == "Loser of #{match2.bout_number}"
    assert @tournament.matches.find { |m|
      m.bracket_position == 'Conso Quarter' && m.bracket_position_number == 2
    }.loser1_name == "Loser of #{match3.bout_number}"
    assert @tournament.matches.find { |m| m.bracket_position == 'Conso Quarter' && m.bracket_position_number == 2 }.loser2_name == 'BYE'

    semis1 = @tournament.matches.find { |match| match.bracket_position == 'Semis' and match.bracket_position_number == 1 }
    semis2 = @tournament.matches.find { |match| match.bracket_position == 'Semis' and match.bracket_position_number == 2 }
    consosemis1 = @tournament.matches.find { |match| match.bracket_position == 'Conso Semis' and match.bracket_position_number == 1 }
    consosemis2 = @tournament.matches.find { |match| match.bracket_position == 'Conso Semis' and match.bracket_position_number == 2 }

    assert consosemis1.loser1_name == "Loser of #{semis2.bout_number}"
    assert consosemis2.loser1_name == "Loser of #{semis1.bout_number}"

    assert @tournament.matches.find { |m|
      m.bracket_position == '5/6' && m.bracket_position_number == 1
    }.loser1_name == "Loser of #{consosemis1.bout_number}"
    assert @tournament.matches.find { |m|
      m.bracket_position == '5/6' && m.bracket_position_number == 1
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

    assert wrestler.reload.placement_points == 3
    assert wrestler2.reload.placement_points == 3
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
