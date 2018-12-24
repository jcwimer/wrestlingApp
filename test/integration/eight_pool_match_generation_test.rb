require 'test_helper'

class EightPoolMatchGenerationTest < ActionDispatch::IntegrationTest
  def setup
    @tournament = Tournament.find(4)
  end

  test "Match generation works" do
    GenerateTournamentMatches.new(@tournament).generate
    assert @tournament.matches.count == 36
    assert @tournament.matches.select{|m| m.bracket_position == "Quarter"}.count == 4
    assert @tournament.matches.select{|m| m.bracket_position == "Semis"}.count == 2
    assert @tournament.matches.select{|m| m.bracket_position == "Conso Semis"}.count == 2
    assert @tournament.matches.select{|m| m.bracket_position == "1/2"}.count == 1
    assert @tournament.matches.select{|m| m.bracket_position == "3/4"}.count == 1
    assert @tournament.matches.select{|m| m.bracket_position == "5/6"}.count == 1
    assert @tournament.matches.select{|m| m.bracket_position == "7/8"}.count == 1
    assert @tournament.matches.select{|m| m.bracket_position == "Pool"}.count == 24
    assert @tournament.weights.first.pools == 8
  end

  test "Seeded wrestlers go to correct pool" do
    GenerateTournamentMatches.new(@tournament).generate
    guy10 = @tournament.wrestlers.select{|w| w.name == "Guy10"}.first
    guy2 = @tournament.wrestlers.select{|w| w.name == "Guy2"}.first
    guy3 = @tournament.wrestlers.select{|w| w.name == "Guy3"}.first
    guy4 = @tournament.wrestlers.select{|w| w.name == "Guy4"}.first
    guy5 = @tournament.wrestlers.select{|w| w.name == "Guy5"}.first
    guy6 = @tournament.wrestlers.select{|w| w.name == "Guy6"}.first
    guy7 = @tournament.wrestlers.select{|w| w.name == "Guy7"}.first
    guy8 = @tournament.wrestlers.select{|w| w.name == "Guy8"}.first
    assert guy10.pool == 1
    assert guy2.pool == 2
    assert guy3.pool == 3
    assert guy4.pool == 4
    assert guy5.pool == 5
    assert guy6.pool == 6
    assert guy7.pool == 7
    assert guy8.pool == 8
  end

  test "Loser names set up correctly" do
    GenerateTournamentMatches.new(@tournament).generate
    assert @tournament.matches.select{|m| m.bracket_position == "Quarter" && m.bracket_position_number == 1}.first.loser1_name == "Winner Pool 1"
    assert @tournament.matches.select{|m| m.bracket_position == "Quarter" && m.bracket_position_number == 1}.first.loser2_name == "Winner Pool 8"
    assert @tournament.matches.select{|m| m.bracket_position == "Quarter" && m.bracket_position_number == 2}.first.loser1_name == "Winner Pool 4"
    assert @tournament.matches.select{|m| m.bracket_position == "Quarter" && m.bracket_position_number == 2}.first.loser2_name == "Winner Pool 5"
    assert @tournament.matches.select{|m| m.bracket_position == "Quarter" && m.bracket_position_number == 3}.first.loser1_name == "Winner Pool 2"
    assert @tournament.matches.select{|m| m.bracket_position == "Quarter" && m.bracket_position_number == 3}.first.loser2_name == "Winner Pool 7"
    assert @tournament.matches.select{|m| m.bracket_position == "Quarter" && m.bracket_position_number == 4}.first.loser1_name == "Winner Pool 3"
    assert @tournament.matches.select{|m| m.bracket_position == "Quarter" && m.bracket_position_number == 4}.first.loser2_name == "Winner Pool 6"
    quarters = @tournament.matches.reload.select{|m| m.bracket_position == "Quarter"}
    assert @tournament.matches.select{|m| m.bracket_position == "Conso Semis" && m.bracket_position_number == 1}.first.loser1_name == "Loser of #{quarters.select{|m| m.bracket_position_number == 1}.first.bout_number}"
    assert @tournament.matches.select{|m| m.bracket_position == "Conso Semis" && m.bracket_position_number == 1}.first.loser2_name == "Loser of #{quarters.select{|m| m.bracket_position_number == 2}.first.bout_number}"
    assert @tournament.matches.select{|m| m.bracket_position == "Conso Semis" && m.bracket_position_number == 2}.first.loser1_name == "Loser of #{quarters.select{|m| m.bracket_position_number == 3}.first.bout_number}"
    assert @tournament.matches.select{|m| m.bracket_position == "Conso Semis" && m.bracket_position_number == 2}.first.loser2_name == "Loser of #{quarters.select{|m| m.bracket_position_number == 4}.first.bout_number}"
    thirdFourth =  @tournament.matches.reload.select{|m| m.bracket_position == "3/4"}.first
    seventhEighth =  @tournament.matches.reload.select{|m| m.bracket_position == "7/8"}.first
    consoSemis = @tournament.matches.reload.select{|m| m.bracket_position == "Conso Semis"}
    assert seventhEighth.loser1_name == "Loser of #{consoSemis.select{|m| m.bracket_position_number == 1}.first.bout_number}"
    assert seventhEighth.loser2_name == "Loser of #{consoSemis.select{|m| m.bracket_position_number == 2}.first.bout_number}"
  end

  test "Each wrestler has two pool matches" do
    GenerateTournamentMatches.new(@tournament).generate
    @tournament.wrestlers.each do |wrestler|
      assert wrestler.pool_matches.size == 2
    end
  end

  test "Placement points are given when moving through bracket" do
    GenerateTournamentMatches.new(@tournament).generate
    match = @tournament.matches.select{|m| m.bracket_position == "Quarter"}.first
    wrestler = @tournament.wrestlers.select{|w| w.name == "Guy10"}.first
    match.w1 = wrestler.id
    match.save
    assert wrestler.reload.placement_points == 3

    match2 = @tournament.matches.select{|m| m.bracket_position == "Semis"}.first
    match2.w1 = wrestler.id
    match2.save
    assert wrestler.reload.placement_points == 9
  end
end
