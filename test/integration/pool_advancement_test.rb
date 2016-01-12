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
  
  def sixteenManToSemi
    matches = @matches
    endMatch(1013,"Guy22",matches)
    endMatch(1014,"Guy29",matches)
    endMatch(2012,"Guy37",matches)
    endMatch(2013,"Guy22",matches)
    endMatch(3012,"Guy29",matches)
    endMatch(3013,"Guy22",matches)
    endMatch(1015,"Guy36",matches)
    endMatch(1016,"Guy32",matches)
    endMatch(2014,"Guy23",matches)
    endMatch(2015,"Guy36",matches)
    endMatch(3014,"Guy32",matches)
    endMatch(3015,"Guy36",matches)
    endMatch(1017,"Guy31",matches)
    endMatch(1018,"Guy35",matches)
    endMatch(2016,"Guy27",matches)
    endMatch(2017,"Guy31",matches)
    endMatch(3016,"Guy35",matches)
    endMatch(3017,"Guy31",matches)
    endMatch(1019,"Guy34",matches)
    endMatch(1020,"Guy26",matches)
    endMatch(2018,"Guy30",matches)
    endMatch(2019,"Guy34",matches)
    endMatch(3018,"Guy26",matches)
    endMatch(3019,"Guy34",matches)
  end
  
  
  def sevenManTwoPoolToSemi
    matches = @matches
    endMatch(1006,"Casey Davis",matches)
    endMatch(1007,"Ethan Leapley",matches)
    endMatch(2006,"Ethan Leapley",matches)
    endMatch(2007,"Casey Davis",matches)
    endMatch(3006,"Clayton Ray",matches)
    endMatch(3007,"Ethan Leapley",matches)
    endMatch(1008,"Kameron Teacher",matches)
    endMatch(2008,"Kameron Teacher",matches)
    endMatch(3008,"Robbie Fusner",matches)
  end
  
  def sevenManTwoPoolSemiToFinals
    sevenManTwoPoolToSemi
    matches = @matches
    endMatch(4005,"Casey Davis",matches)
    endMatch(4004,"Ethan Leapley",matches)
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
  
  def nineManBracketPoolTwoGuyThreeMostDecisionPoints
    matches = @matches.select{|m| m.weight_id == 3 && m.bracket_position == "Pool"}
    endMatchExtraPoints(1004,"Guy9",matches)
    endMatch(1005,"Guy7",matches)
    endMatchExtraPoints(2004,"Guy3",matches)
    endMatch(2005,"Guy9",matches)
    endMatch(3004,"Guy7",matches)
    endMatchExtraPoints(3005,"Guy3",matches)
  end
  
  def nineManBracketPoolTwoGuyThreeQuickestPin
    matches = @matches.select{|m| m.weight_id == 3 && m.bracket_position == "Pool"}
    endMatchWithQuickPin(1004,"Guy9",matches)
    endMatchWithPin(1005,"Guy7",matches)
    endMatchWithQuickPin(2004,"Guy3",matches)
    endMatchWithPin(2005,"Guy9",matches)
    endMatchWithPin(3004,"Guy7",matches)
    endMatchWithQuickestPin(3005,"Guy3",matches)
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
    elevenManBracketToQuarter
    matches = @matches
    endMatch(4006,"Guy11",matches)
    endMatch(4007,"Guy14",matches)
    endMatch(4008,"Guy12",matches)
    endMatch(4009,"Guy15",matches)
  end
  
  def elevenManBracketToFinals
    elevenManBracketToSemis
    matches = @matches
    endMatch(5004,"Guy11",matches)
    endMatch(5005,"Guy12",matches)
    endMatch(5006,"Guy16",matches)
    endMatch(5007,"Guy17",matches)
  end
  
  def elevenManBracketFinished
    elevenManBracketToFinals
    matches = @matches
    endMatch(6004,"Guy11",matches)
    endMatch(6005,"Guy14",matches)
    endMatch(6006,"Guy16",matches)
    endMatch(6007,"Guy19",matches)
  end
  
  def extraDoesNotScoreTeamPoints
    matches = @matches
    wrestlerName = "Guy22"
    wrestler = Wrestler.find(translateNameToId(wrestlerName))
    wrestler.extra = true
    wrestler.save
    endMatch(1013,"Guy22",matches)
  end
  
  def endMatch(bout,winner,matches)
     match = Match.where(bout_number: bout).first
     match.finished = 1
     match.winner_id = translateNameToId(winner)
     match.win_type = "Decision"
     match.score = 1-0
     
     match.save
  end
  
  def endMatchExtraPoints(bout,winner,matches)
     match = Match.where(bout_number: bout).first
     match.finished = 1
     match.winner_id = translateNameToId(winner)
     match.win_type = "Decision"
     match.score = 0-2
     
     match.save
  end
  
  def endMatchWithMajor(bout,winner,matches)
     match = Match.where(bout_number: bout).first
     match.finished = 1
     match.winner_id = translateNameToId(winner)
     match.win_type = "Major"
     match.score = 8-0
     
     match.save
  end
  
  def endMatchWithTech(bout,winner,matches)
     match = Match.where(bout_number: bout).first
     match.finished = 1
     match.winner_id = translateNameToId(winner)
     match.win_type = "Tech Fall"
     
     match.save
  end
  
  def endMatchWithPin(bout,winner,matches)
     match = Match.where(bout_number: bout).first
     match.finished = 1
     match.winner_id = translateNameToId(winner)
     match.win_type = "Pin"
     match.score = "5:00"
    
     match.save
  end
  
  def endMatchWithQuickestPin(bout,winner,matches)
     match = Match.where(bout_number: bout).first
     match.finished = 1
     match.winner_id = translateNameToId(winner)
     match.win_type = "Pin"
     match.score = "0:20"
     
     match.save
  end
  
  def endMatchWithQuickPin(bout,winner,matches)
     match = Match.where(bout_number: bout).first
     match.finished = 1
     match.winner_id = translateNameToId(winner)
     match.win_type = "Pin"
     match.score = "1:20"

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
  
  
  
  test "nine man pool 2 mostDecisionPointsScored tie breaker finalist guy 3" do
    wrestler = Wrestler.where("name = ?", "Guy3").first
    nineManBracketPoolTwoGuyThreeMostDecisionPoints
    assert_equal 6000, wrestler.boutByRound(6)
  end
  
  test "nine man conso finals mostDecisionPointsScored tie breaker guy 9" do
    nineManBracketPoolTwoGuyThreeMostDecisionPoints
    wrestler = Wrestler.where("name = ?", "Guy9").first
    assert_equal 6001, wrestler.boutByRound(6)
  end
  
  test "nine man pool 2 QuickestPin tie breaker finalist guy 3" do
    wrestler = Wrestler.where("name = ?", "Guy3").first
    nineManBracketPoolTwoGuyThreeQuickestPin
    assert_equal 6000, wrestler.boutByRound(6)
  end
  
  test "nine man conso finals QuickestPin tie breaker guy 9" do
    nineManBracketPoolTwoGuyThreeQuickestPin
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
    assert_equal 20, wrestler1.totalTeamPoints
    #Won two in pool
    assert_equal 16, wrestler2.totalTeamPoints
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
    elevenManBracketToFinals
    wrestler = Wrestler.where("name = ?", "Guy16").first

    assert_equal 6, wrestler.placementPoints
  end
  
  test "advancement points 7/8" do
    elevenManBracketToFinals
    wrestler = Wrestler.where("name = ?", "Guy19").first

    assert_equal 3, wrestler.placementPoints
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
    elevenManBracketFinished
    wrestler = Wrestler.where("name = ?", "Guy16").first

    assert_equal 7, wrestler.placementPoints
  end
  
  test "advancement points winner 7/8" do
    elevenManBracketFinished
    wrestler = Wrestler.where("name = ?", "Guy19").first

    assert_equal 4, wrestler.placementPoints
  end
  
  test "bonus points major" do
    endMatchWithMajor(2002,"Guy2",@matches)
    wrestler1 = Wrestler.where("name = ?", "Guy2").first
    assert_equal 3, wrestler1.teamPointsEarned
  end
  
  test "bonus points pin" do
    endMatchWithPin(2002,"Guy2",@matches)
    wrestler1 = Wrestler.where("name = ?", "Guy2").first
    assert_equal 4, wrestler1.teamPointsEarned
  end
  
  test "bonus points tech fall" do
    endMatchWithTech(2002,"Guy2",@matches)
    wrestler1 = Wrestler.where("name = ?", "Guy2").first
    assert_equal 3.5, wrestler1.teamPointsEarned
  end
  
  test "pool team points win" do
    endMatch(2002,"Guy2",@matches)
    wrestler1 = Wrestler.where("name = ?", "Guy2").first
    assert_equal 2, wrestler1.teamPointsEarned
  end
  
  test "advancement points fourPoolsToQuarter Quarter" do
    elevenManBracketToQuarter
    wrestler1 = Wrestler.where("name = ?", "Guy11").first
    assert_equal 3, wrestler1.placementPoints
  end
  
  test "advancement points fourPoolsToQuarter Semis" do
    elevenManBracketToSemis
    wrestler = Wrestler.where("name = ?", "Guy11").first

    assert_equal 9, wrestler.placementPoints
  end
  
  test "advancement points twoPoolsToSemi Semis" do
    sevenManTwoPoolToSemi
    wrestler = Wrestler.where("name = ?", "Casey Davis").first

    assert_equal 9, wrestler.placementPoints
  end
  
  test "advancement points twoPoolsToSemi Finals" do
    sevenManTwoPoolSemiToFinals
    wrestler = Wrestler.where("name = ?", "Casey Davis").first

    assert_equal 12, wrestler.placementPoints
  end
  
  test "advancement points fourPoolsToSemi Semis and Conso Semis" do
    sixteenManToSemi
    wrestler = Wrestler.where("name = ?", "Guy22").first

    assert_equal 9, wrestler.placementPoints
    
    wrestler = Wrestler.where("name = ?", "Guy29").first

    assert_equal 3, wrestler.placementPoints
  end
  
  test "extra does not score points but does get pool criteria" do
    extraDoesNotScoreTeamPoints
    wrestler = Wrestler.where("name = ?", "Guy22").first
    
    assert_equal 0, wrestler.totalTeamPoints
    assert_equal 2, wrestler.teamPointsEarned
  end
    
  test "Test mat assignment when adding a mat and when destroying a mat" do
    @mat2 = Mat.new
    @mat2.name = "2"
    @mat2.tournament_id = 1
    @mat2.save
    assert_equal 4, @mat2.matches.size
    elevenManBracketFinished
    @mat2.destroy
    @mat1 = Mat.find(1)
    assert_equal 4, @mat1.matches.size
  end
  
  test "Championship bracket wins are 2pts" do
    elevenManBracketToQuarter
    assert_equal 7, Wrestler.where("name = ?", "Guy11").first.teamPointsEarned
    matches = @matches
    endMatch(4006,"Guy11",matches)
    assert_equal 15, Wrestler.where("name = ?", "Guy11").first.teamPointsEarned
    endMatch(4007,"Guy14",matches)
    endMatch(5004,"Guy11",matches)
    assert_equal 20, Wrestler.where("name = ?", "Guy11").first.teamPointsEarned
  end
  
  test "Conso bracket wins are 1pt" do
    elevenManBracketToSemis
    assert_equal 7, Wrestler.where("name = ?", "Guy16").first.teamPointsEarned
    matches = @matches
    endMatch(5006,"Guy16",matches)
    assert_equal 11, Wrestler.where("name = ?", "Guy16").first.teamPointsEarned
  end
  
end
