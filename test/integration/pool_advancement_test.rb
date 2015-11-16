require 'test_helper'

class PoolAdvancementTest < ActionDispatch::IntegrationTest

  def setup
    @tournament = Tournament.find(1)
    @tournament.generateMatchups
  end

  def showNineManWeightThreePoolTwoMatches
    matches = @tournament.matches.select{|m| m.weight_id == 3 && m.bracket_position == "Pool" && m.poolNumber == 2}
    matches.each do |m|
      puts "Bout: #{m.bout_number} #{m.w1_name} vs #{m.w2_name} Pool: #{m.poolNumber}"
    end
  end

  def nineManBracketPoolOneOutrightWinner
     matches = @tournament.matches.select{|m| m.weight_id == 3 && m.bracket_position == "Pool"}
     endMatch(1002,"Guy8",matches)
     endMatch(1003,"Guy10",matches)
     endMatch(2002,"Guy2",matches)
     endMatch(2003,"Guy8",matches)
     endMatch(3003,"Guy2",matches)
     endMatch(4002,"Guy8",matches)
     endMatch(4003,"Guy2",matches)
     endMatch(5002,"Guy2",matches)
     endMatch(5003,"Guy5",matches)
     endMatch(3002,"Guy5",matches)
  end
  
  def nineManBracketPoolTwoGuyNineHeadToHead
    matches = @tournament.matches.select{|m| m.weight_id == 3 && m.bracket_position == "Pool"}
    endMatch(1004,"Guy4",matches)
    endMatch(1005,"Guy3",matches)
    endMatch(2004,"Guy3",matches)
    endMatch(2005,"Guy9",matches)
    endMatch(3004,"Guy7",matches)
    endMatch(3005,"Guy9",matches)
  end
  
  def nineManBracketPoolTwoGuyThreeHeadToHead
    matches = @tournament.matches.select{|m| m.weight_id == 3 && m.bracket_position == "Pool"}
    endMatch(1004,"Guy9",matches)
    endMatch(1005,"Guy3",matches)
    endMatch(2004,"Guy4",matches)
    endMatch(2005,"Guy9",matches)
    endMatch(3004,"Guy7",matches)
    #DEDUCTED POINTS SHOULD NOT MATTER FOR HEAD TO HEAD
    deduct = Teampointadjust.new
    deduct.wrestler_id = translateNameToId("Guy3")
    deduct.points = 1
    deduct.save
    endMatch(3005,"Guy3",matches)
  end
  
  def nineManBracketPoolTwoGuyThreeDeductedPoints
    matches = @tournament.matches.select{|m| m.weight_id == 3 && m.bracket_position == "Pool"}
    endMatch(1004,"Guy9",matches)
    endMatch(1005,"Guy7",matches)
    endMatch(2004,"Guy3",matches)
    endMatch(2005,"Guy9",matches)
    endMatch(3004,"Guy7",matches)
    endMatch(3005,"Guy3",matches)
    deduct = Teampointadjust.new
    deduct.wrestler_id = translateNameToId("Guy7")
    deduct.points = 1
    deduct.save
  end
  
  def endMatch(bout,winner,matches)
     match = matches.select{|m| m.bout_number == bout}.first
     match.finished = 1
     match.winner_id = translateNameToId(winner)
     match.win_type = "Decision"
     #Need to manually assign mat_id because thise weight class is not currently assigned a mat
     mat = @tournament.mats.first
     match.mat_id = mat.id
     match.save
  end
  def translateNameToId(wrestler)
    Wrestler.where("name = ?", wrestler).first.id
  end

  test "nine man outright finals advance" do
    nineManBracketPoolOneOutrightWinner
    wrestler = Wrestler.where("name = ?", "Guy2").first
    assert_equal 6000, wrestler.boutByRound(6)
  end

  test "nine man outright conso finals advance" do
    nineManBracketPoolOneOutrightWinner
    wrestler = Wrestler.where("name = ?", "Guy8").first
    assert_equal 6001, wrestler.boutByRound(6)
  end

  test "nine man pool 2 man to man tie breaker finalist guy 9" do
    wrestler = Wrestler.where("name = ?", "Guy9").first
    nineManBracketPoolTwoGuyNineHeadToHead
    assert_equal 6000, wrestler.boutByRound(6)
  end
  
  test "nine man pool 2 man to man tie breaker finalist guy 3" do
    wrestler = Wrestler.where("name = ?", "Guy3").first
    nineManBracketPoolTwoGuyThreeHeadToHead
    assert_equal 6000, wrestler.boutByRound(6)
  end
  
  test "nine man conso finals man to man tie breaker guy 3" do
    nineManBracketPoolTwoGuyNineHeadToHead
    wrestler = Wrestler.where("name = ?", "Guy3").first
    assert_equal 6001, wrestler.boutByRound(6)
  end
  
  test "nine man conso finals man to man tie breaker guy 9" do
    nineManBracketPoolTwoGuyThreeHeadToHead
    wrestler = Wrestler.where("name = ?", "Guy9").first
    assert_equal 6001, wrestler.boutByRound(6)
  end
  
  test "nine man pool 2 deductedPoints tie breaker finalist guy 3" do
    wrestler = Wrestler.where("name = ?", "Guy3").first
    nineManBracketPoolTwoGuyThreeDeductedPoints
    assert_equal 6000, wrestler.boutByRound(6)
  end
  
  test "nine man conso finals deductedPoints tie breaker guy 9" do
    nineManBracketPoolTwoGuyThreeDeductedPoints
    wrestler = Wrestler.where("name = ?", "Guy9").first
    assert_equal 6001, wrestler.boutByRound(6)
  end
end
