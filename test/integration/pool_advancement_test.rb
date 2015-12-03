require 'test_helper'

class PoolAdvancementTest < ActionDispatch::IntegrationTest

  def setup
    @tournament = Tournament.find(1)
    @tournament.generateMatchups
    @matches = @tournament.matches
  end

  def showMatches
    matches = Match.where(weight_id: 4)
    # matches = @matches.select{|m| m.weight_id == 4}
    matches.each do |m|
      puts "Bout: #{m.bout_number} #{m.w1_name} vs #{m.w2_name} #{m.bracket_position} #{m.poolNumber}"
    end
  end

  def nineManBracketPoolOneOutrightWinnerGuyTwo
     matches = @matches.select{|m| m.weight_id == 3 && m.bracket_position == "Pool"}
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
    matches = @matches.select{|m| m.weight_id == 3 && m.bracket_position == "Pool"}
    endMatch(1004,"Guy4",matches)
    endMatch(1005,"Guy3",matches)
    endMatch(2004,"Guy3",matches)
    endMatch(2005,"Guy9",matches)
    endMatch(3004,"Guy7",matches)
    endMatch(3005,"Guy9",matches)
  end
  
  def nineManBracketPoolTwoGuyThreeHeadToHead
    matches = @matches.select{|m| m.weight_id == 3 && m.bracket_position == "Pool"}
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
    matches = @matches.select{|m| m.weight_id == 3 && m.bracket_position == "Pool"}
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
  
  def nineManBracketPoolTwoGuyThreeTeamPoints
    matches = @matches.select{|m| m.weight_id == 3 && m.bracket_position == "Pool"}
    endMatch(1004,"Guy9",matches)
    endMatch(1005,"Guy7",matches)
    endMatchWithMajor(2004,"Guy3",matches)
    endMatch(2005,"Guy9",matches)
    endMatch(3004,"Guy7",matches)
    endMatch(3005,"Guy3",matches)
  end
  
  def nineManBracketPoolTwoGuyThreeMostPins
    matches = @matches.select{|m| m.weight_id == 3 && m.bracket_position == "Pool"}
    endMatchWithMajor(1004,"Guy9",matches)
    endMatch(1005,"Guy7",matches)
    endMatchWithPin(2004,"Guy3",matches)
    endMatchWithMajor(2005,"Guy9",matches)
    endMatch(3004,"Guy7",matches)
    endMatch(3005,"Guy3",matches)
  end
  
  def nineManBracketPoolOneGuyEightMostTechs
    matches = @matches.select{|m| m.weight_id == 3 && m.bracket_position == "Pool"}
    endMatchWithTech(1002,"Guy8",matches)
    endMatchWithMajor(1003,"Guy10",matches)
    endMatchWithMajor(2002,"Guy2",matches)
    endMatchWithTech(2003,"Guy8",matches)
    endMatchWithMajor(3002,"Guy10",matches)
    endMatchWithMajor(3003,"Guy2",matches)
    endMatch(4002,"Guy8",matches)
    endMatchWithMajor(4003,"Guy2",matches)
    endMatchWithMajor(5002,"Guy10",matches)
    endMatch(5003,"Guy5",matches)
  end
  
  def elevenManBracketToQuarter
    matches = @matches
    endMatch(1009,"Guy11",matches)
    endMatch(2009,"Guy11",matches)
    endMatch(3009,"Guy17",matches)
    endMatch(1010,"Guy12",matches)
    endMatch(2010,"Guy12",matches)
    endMatch(3010,"Guy16",matches)
    endMatch(1011,"Guy15",matches)
    endMatch(2011,"Guy15",matches)
    endMatch(3011,"Guy19",matches)
    endMatch(1012,"Guy14",matches)
  end
  def elevenManBracketToSemis
    matches = @matches
    endMatch(4006,"Guy11",matches)
    endMatch(4007,"Guy14",matches)
    endMatch(4008,"Guy12",matches)
    endMatch(4009,"Guy15",matches)
  end
  
  def elevenManBracketToFinals
    matches = @matches
    endMatch(5006,"Guy11",matches)
    endMatch(5007,"Guy12",matches)
    endMatch(5008,"Guy16",matches)
    endMatch(5009,"Guy17",matches)
  end
  
  def elevenManBracketFinished
    matches = @matches
    endMatch(6002,"Guy11",matches)
    endMatch(6003,"Guy14",matches)
    endMatch(6004,"Guy16",matches)
    endMatch(6005,"Guy19",matches)
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
  
  def endMatchWithMajor(bout,winner,matches)
     match = matches.select{|m| m.bout_number == bout}.first
     match.finished = 1
     match.winner_id = translateNameToId(winner)
     match.win_type = "Major"
     #Need to manually assign mat_id because thise weight class is not currently assigned a mat
     mat = @tournament.mats.first
     match.mat_id = mat.id
     match.save
  end
  
  def endMatchWithTech(bout,winner,matches)
     match = matches.select{|m| m.bout_number == bout}.first
     match.finished = 1
     match.winner_id = translateNameToId(winner)
     match.win_type = "Tech Fall"
     #Need to manually assign mat_id because thise weight class is not currently assigned a mat
     mat = @tournament.mats.first
     match.mat_id = mat.id
     match.save
  end
  
  def endMatchWithPin(bout,winner,matches)
     match = matches.select{|m| m.bout_number == bout}.first
     match.finished = 1
     match.winner_id = translateNameToId(winner)
     match.win_type = "Pin"
     #Need to manually assign mat_id because thise weight class is not currently assigned a mat
     mat = @tournament.mats.first
     match.mat_id = mat.id
     match.save
  end
  
  def translateNameToId(wrestler)
    Wrestler.where("name = ?", wrestler).first.id
  end

  test "nine man outright finals advance" do
    nineManBracketPoolOneOutrightWinnerGuyTwo
    wrestler = Wrestler.where("name = ?", "Guy2").first
    assert_equal 6000, wrestler.boutByRound(6)
  end

  test "nine man outright conso finals advance" do
    nineManBracketPoolOneOutrightWinnerGuyTwo
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
  
  test "nine man pool 2 teamPoints tie breaker finalist guy 3" do
    wrestler = Wrestler.where("name = ?", "Guy3").first
    nineManBracketPoolTwoGuyThreeTeamPoints
    assert_equal 6000, wrestler.boutByRound(6)
  end
  
  test "nine man conso finals teamPoints tie breaker guy 9" do
    nineManBracketPoolTwoGuyThreeTeamPoints
    wrestler = Wrestler.where("name = ?", "Guy9").first
    assert_equal 6001, wrestler.boutByRound(6)
  end
  
  test "nine man pool 2 mostPins tie breaker finalist guy 3" do
    wrestler = Wrestler.where("name = ?", "Guy3").first
    nineManBracketPoolTwoGuyThreeMostPins
    assert_equal 6000, wrestler.boutByRound(6)
  end
  
  test "nine man conso finals mostPins tie breaker guy 9" do
    nineManBracketPoolTwoGuyThreeMostPins
    wrestler = Wrestler.where("name = ?", "Guy9").first
    assert_equal 6001, wrestler.boutByRound(6)
  end
  
  test "nine man pool 1 mostTechs tie breaker finalist guy 8" do
    nineManBracketPoolOneGuyEightMostTechs
    wrestler = Wrestler.where("name = ?", "Guy8").first
    assert_equal 6000, wrestler.boutByRound(6)
  end
  
  test "nine man conso finals mostTechs tie breaker guy 10" do
    nineManBracketPoolOneGuyEightMostTechs
    wrestler = Wrestler.where("name = ?", "Guy10").first
    assert_equal 6001, wrestler.boutByRound(6)
  end
  
  test "twoPoolsToFinal total points finals" do
    nineManBracketPoolOneOutrightWinnerGuyTwo
    nineManBracketPoolTwoGuyThreeHeadToHead
    wrestler1 = Wrestler.where("name = ?", "Guy2").first
    wrestler2 = Wrestler.where("name = ?", "Guy3").first
    #Won four in pool
    assert_equal 16, wrestler1.totalTeamPoints
    #Won two in pool but was deducted a point
    assert_equal 13, wrestler2.totalTeamPoints
  end
  
  test "advancement points 1/2" do
    nineManBracketPoolOneOutrightWinnerGuyTwo
    wrestler1 = Wrestler.where("name = ?", "Guy2").first
    assert_equal 12, wrestler1.placementPoints
  end
  
  test "advancement points 3/4" do
    nineManBracketPoolOneOutrightWinnerGuyTwo
    wrestler1 = Wrestler.where("name = ?", "Guy8").first
    assert_equal 9, wrestler1.placementPoints
  end
  
  test "advancement points 5/6" do
  
  end
  
  test "advancement points 7/8" do
  
  end
  
  test "advancement points winner 1/2" do
    nineManBracketPoolOneOutrightWinnerGuyTwo
    nineManBracketPoolTwoGuyThreeHeadToHead
    endMatch(6000,"Guy2",@matches)
    wrestler1 = Wrestler.where("name = ?", "Guy2").first
    assert_equal 16, wrestler1.placementPoints
  end
  
  test "advancement points winner 3/4" do
    nineManBracketPoolOneOutrightWinnerGuyTwo
    nineManBracketPoolTwoGuyThreeHeadToHead
    endMatch(6001,"Guy8",@matches)
    wrestler1 = Wrestler.where("name = ?", "Guy8").first
    assert_equal 10, wrestler1.placementPoints
  end
  
  test "advancement points winner 5/6" do
    
  end
  
  test "advancement points winner 7/8" do
  
  end
  
  test "bonus points major" do
    endMatchWithMajor(2002,"Guy2",@matches)
    wrestler1 = Wrestler.where("name = ?", "Guy2").first
    assert_equal 2, wrestler1.teamPointsEarned
  end
  
  test "bonus points pin" do
    endMatchWithPin(2002,"Guy2",@matches)
    wrestler1 = Wrestler.where("name = ?", "Guy2").first
    assert_equal 3, wrestler1.teamPointsEarned
  end
  
  test "bonus points tech fall" do
    endMatchWithTech(2002,"Guy2",@matches)
    wrestler1 = Wrestler.where("name = ?", "Guy2").first
    assert_equal 2.5, wrestler1.teamPointsEarned
  end
  
  test "pool team points win" do
    endMatch(2002,"Guy2",@matches)
    wrestler1 = Wrestler.where("name = ?", "Guy2").first
    assert_equal 1, wrestler1.teamPointsEarned
  end
  
  test "advancement points fourPoolsToQuarter Quarter" do
    elevenManBracketToQuarter
    wrestler1 = Wrestler.where("name = ?", "Guy11").first
    assert_equal 3, wrestler1.placementPoints
  end
  
  test "advancement points fourPoolsToQuarter Semis" do
    # elevenManBracketToQuarter
    # elevenManBracketToSemis
    # showMatches
    
    matches = @matches
    endMatch(1009,"Guy11",matches)
    endMatch(2009,"Guy11",matches)
    endMatch(3009,"Guy17",matches)
    endMatch(1010,"Guy12",matches)
    endMatch(2010,"Guy12",matches)
    endMatch(3010,"Guy16",matches)
    endMatch(1011,"Guy15",matches)
    endMatch(2011,"Guy15",matches)
    endMatch(3011,"Guy19",matches)
    endMatch(1012,"Guy14",matches)

    endMatch(4006,"Guy11",matches)
    endMatch(4007,"Guy14",matches)
    endMatch(4008,"Guy12",matches)
    endMatch(4009,"Guy15",matches)

    # showMatches

    wrestler = Wrestler.where("name = ?", "Guy11").first
    match = Match.where(bout_number: 4006).first
    puts match.inspect
    # puts Wrestler.find(match.winner_id).name
    # match = Match.where(bout_number: 5006).first
    # puts match.inspect
    puts wrestler.weight.allPoolMatchesFinished(wrestler.generatePoolNumber)
    puts wrestler.finishedBracketMatches.size
    puts wrestler.lastMatch.bout_number
    puts wrestler.winnerOfLastMatch?
    puts wrestler.nextMatchPositionNumber.ceil
    puts wrestler.nextMatchPositionNumber
    match = Match.where("bracket_position = ? AND bracket_position_number = ? AND weight_id = ?","Semis",wrestler.nextMatchPositionNumber.ceil,wrestler.weight_id).first
    puts match.bout_number
    assert_equal 9, wrestler.placementPoints
  end
  
  test "advancement points twoPoolsToSemi Semis" do
  
  end
  
  test "advancement points twoPoolsToSemi Conso Semis" do
  
  end
  
  test "advancement points fourPoolsToSemi Semis" do
  
  end
  
  test "advancement points fourPoolsToSemi Conso Semis" do
  
  end
  
  
  
end
