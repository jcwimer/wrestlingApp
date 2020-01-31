require 'test_helper'

class DoubleEliminationEightManMatchGeneration < ActionDispatch::IntegrationTest
  def setup
    create_double_elim_tournament_single_weight_1_6(6)
  end

  test "Match generation works" do
    assert @tournament.matches.count == 13
    assert @tournament.matches.select{|m| m.bracket_position == "1/2"}.count == 1
    assert @tournament.matches.select{|m| m.bracket_position == "3/4"}.count == 1
    assert @tournament.matches.select{|m| m.bracket_position == "5/6"}.count == 1
    assert @tournament.matches.select{|m| m.bracket_position == "Quarter"}.count == 4
    assert @tournament.matches.select{|m| m.bracket_position == "Semis"}.count == 2
    assert @tournament.matches.select{|m| m.bracket_position == "Conso Quarter"}.count == 2
    assert @tournament.matches.select{|m| m.bracket_position == "Conso Semis"}.count == 2
  end

  test "Seeded wrestlers have correct first line" do
    @tournament.matches.reload
    match1 = @tournament.matches.select{|match| match.round == 1 and match.bracket_position_number == 1}.first
    match2 = @tournament.matches.select{|match| match.round == 1 and match.bracket_position_number == 2}.first
    match3 = @tournament.matches.select{|match| match.round == 1 and match.bracket_position_number == 3}.first
    match4 = @tournament.matches.select{|match| match.round == 1 and match.bracket_position_number == 4}.first
    
    assert match1.wrestler1.bracket_line == 1
    assert match1.loser2_name == "BYE"

    assert match2.wrestler1.bracket_line == 4
    assert match2.wrestler2.bracket_line == 5

    assert match3.wrestler1.bracket_line == 3
    assert match3.wrestler2.bracket_line == 6

    assert match4.wrestler1.bracket_line == 2
    assert match4.loser2_name == "BYE"

  end

  test "Byes are advanced correctly" do
    @tournament.matches.reload
    match1 = @tournament.matches.select{|match| match.round == 2 and match.bracket_position == "Semis" and match.bracket_position_number == 1}.first
    match2 = @tournament.matches.select{|match| match.round == 2 and match.bracket_position == "Semis" and match.bracket_position_number == 2}.first

    assert match1.wrestler1.name == "Test1"
    assert match2.wrestler2.name == "Test2"
  end

  test "Loser names set up correctly" do
    @tournament.matches.reload
    match1 = @tournament.matches.select{|match| match.round == 1 and match.bracket_position_number == 1}.first
    match2 = @tournament.matches.select{|match| match.round == 1 and match.bracket_position_number == 2}.first
    match3 = @tournament.matches.select{|match| match.round == 1 and match.bracket_position_number == 3}.first
    match4 = @tournament.matches.select{|match| match.round == 1 and match.bracket_position_number == 4}.first

    assert @tournament.matches.select{|m| m.bracket_position == "Conso Quarter" && m.bracket_position_number == 1}.first.loser1_name == "BYE"
    assert @tournament.matches.select{|m| m.bracket_position == "Conso Quarter" && m.bracket_position_number == 1}.first.loser2_name == "Loser of #{match2.bout_number}"
    assert @tournament.matches.select{|m| m.bracket_position == "Conso Quarter" && m.bracket_position_number == 2}.first.loser1_name == "Loser of #{match3.bout_number}"
    assert @tournament.matches.select{|m| m.bracket_position == "Conso Quarter" && m.bracket_position_number == 2}.first.loser2_name == "BYE"

    semis1 = @tournament.matches.select{|match| match.bracket_position == "Semis" and match.bracket_position_number == 1}.first
    semis2 = @tournament.matches.select{|match| match.bracket_position == "Semis" and match.bracket_position_number == 2}.first
    consosemis1 = @tournament.matches.select{|match| match.bracket_position == "Conso Semis" and match.bracket_position_number == 1}.first
    consosemis2 = @tournament.matches.select{|match| match.bracket_position == "Conso Semis" and match.bracket_position_number == 2}.first

    assert consosemis1.loser1_name == "Loser of #{semis2.bout_number}"  
    assert consosemis2.loser1_name == "Loser of #{semis1.bout_number}"  

    assert @tournament.matches.select{|m| m.bracket_position == "5/6" && m.bracket_position_number == 1}.first.loser1_name == "Loser of #{consosemis1.bout_number}"
    assert @tournament.matches.select{|m| m.bracket_position == "5/6" && m.bracket_position_number == 1}.first.loser2_name == "Loser of #{consosemis2.bout_number}" 
  end

  test "Placement points are given when moving through bracket" do
    match = @tournament.matches.select{|m| m.bracket_position == "Semis"}.first
    wrestler = get_wrestler_by_name("Test1")
    match.w1 = wrestler.id
    match.save

    match2 = @tournament.matches.select{|m| m.bracket_position == "Conso Semis"}.first
    wrestler2 = get_wrestler_by_name("Test2")
    match2.w1 = wrestler.id
    match2.save

    assert wrestler.reload.placement_points == 3
    assert wrestler2.reload.placement_points == 3
  end

  test "Run through all matches works" do
    @tournament.matches.sort_by{ |match| match.bout_number }.each do |match|
      match.reload
      if match.finished != 1 and match.w1 and match.w2
          match.winner_id = match.w1
          match.win_type = "Decision"
          match.score = "0-0"
          match.finished = 1
          match.save
      end
    end
    assert @tournament.matches.reload.select{|m| m.finished == 0}.count == 0
  end
end