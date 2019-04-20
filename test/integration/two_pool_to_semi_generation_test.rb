require 'test_helper'

class TwoPoolToSemiGenerationTest < ActionDispatch::IntegrationTest
  def setup
    create_pool_tournament_single_weight(8)
  end

  test "Match generation works" do
    assert @tournament.matches.count == 16
    assert @tournament.matches.select{|m| m.bracket_position == "Semis"}.count == 2
    assert @tournament.matches.select{|m| m.bracket_position == "1/2"}.count == 1
    assert @tournament.matches.select{|m| m.bracket_position == "3/4"}.count == 1
    assert @tournament.matches.select{|m| m.bracket_position == "Pool"}.count == 12
    assert @tournament.weights.first.pools == 2
  end

  test "Seeded wrestlers go to correct pool" do
    guy1 = get_wrestler_by_name("Test1")
    guy2 = get_wrestler_by_name("Test2")
    guy3 = get_wrestler_by_name("Test3")
    guy4 = get_wrestler_by_name("Test4")
    guy5 = get_wrestler_by_name("Test5")
    guy6 = get_wrestler_by_name("Test6")
    guy7 = get_wrestler_by_name("Test7")
    guy8 = get_wrestler_by_name("Test8")
    assert guy1.pool == 1
    assert guy2.pool == 2
    assert guy3.pool == 2
    assert guy4.pool == 1
  end

  test "Loser names set up correctly" do
    assert @tournament.matches.select{|m| m.bracket_position == "Semis" && m.bracket_position_number == 1}.first.loser1_name == "Winner Pool 1"
    assert @tournament.matches.select{|m| m.bracket_position == "Semis" && m.bracket_position_number == 1}.first.loser2_name == "Runner Up Pool 2"
    assert @tournament.matches.select{|m| m.bracket_position == "Semis" && m.bracket_position_number == 2}.first.loser1_name == "Winner Pool 2"
    assert @tournament.matches.select{|m| m.bracket_position == "Semis" && m.bracket_position_number == 2}.first.loser2_name == "Runner Up Pool 1"
    thirdFourth =  @tournament.matches.reload.select{|m| m.bracket_position == "3/4"}.first
    semis = @tournament.matches.reload.select{|m| m.bracket_position == "Semis"}
    assert thirdFourth.loser1_name == "Loser of #{semis.select{|m| m.bracket_position_number == 1}.first.bout_number}"
    assert thirdFourth.loser2_name == "Loser of #{semis.select{|m| m.bracket_position_number == 2}.first.bout_number}"
  end

  test "Each wrestler has two pool matches" do
    @tournament.wrestlers.each do |wrestler|
      assert wrestler.pool_matches.size == 3
    end
  end

  test "Placement points are given when moving through bracket" do
    match = @tournament.matches.select{|m| m.bracket_position == "Semis"}.first
    wrestler = get_wrestler_by_name("Test1")
    match.w1 = wrestler.id
    match.save
    assert wrestler.reload.placement_points == 9
  end

  test "Run through all matches works" do
    @tournament.matches.sort{ |match| match.round }.each do |match|
      match.winner_id = match.w1
      match.save
    end
  end
end
