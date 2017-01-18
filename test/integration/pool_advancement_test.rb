require 'test_helper'

class PoolAdvancementTest < ActionDispatch::IntegrationTest

  def setup
    tournament = Tournament.find(1)
  end
  
  def singlePoolNotFinished
    
    endMatch(1000,"Jackson Lakso")
    endMatch(1001,"Jaden Mattox")
    endMatch(2000,"James Wimer")
    endMatch(2001,"Jaden Mattox")
    endMatch(3000,"Jaden Mattox")
    endMatch(3001,"James Wimer")
    endMatch(4000,"JD Woods")
    endMatch(4001,"James Wimer")
    endMatch(5000,"James Wimer")
  end
  
  def singlePoolFinished
    singlePoolNotFinished
    
    endMatch(5001,"Jackson Lakso")
  end
  
  def sixteenManToSemi
    
    endMatch(1013,"Guy22")
    endMatch(1014,"Guy29")
    endMatch(2012,"Guy29")
    endMatch(2013,"Guy22")
    endMatch(3012,"Guy37")
    endMatch(3013,"Guy22")
    endMatch(1015,"Guy36")
    endMatch(1016,"Guy32")
    endMatch(2014,"Guy36")
    endMatch(2015,"Guy32")
    endMatch(3014,"Guy36")
    endMatch(3015,"Guy23")
    endMatch(1017,"Guy31")
    endMatch(1018,"Guy35")
    endMatch(2016,"Guy35")
    endMatch(2017,"Guy31")
    endMatch(3016,"Guy27")
    endMatch(3017,"Guy31")
    endMatch(1019,"Guy34")
    endMatch(1020,"Guy26")
    endMatch(2018,"Guy30")
    endMatch(2019,"Guy34")
    endMatch(3018,"Guy26")
    endMatch(3019,"Guy34")
  end
  
  
  def sevenManTwoPoolToSemi
    
    endMatch(1006,"Casey Davis")
    endMatch(1007,"Ethan Leapley")
    endMatch(2006,"Clayton Ray")
    endMatch(2007,"Ethan Leapley")
    endMatch(3006,"Ethan Leapley")
    endMatch(3007,"Casey Davis")
    endMatch(1008,"Kameron Teacher")
    endMatch(2008,"Kameron Teacher")
    endMatch(3008,"Robbie Fusner")
  end
  
  def sevenManTwoPoolSemiToFinals
    sevenManTwoPoolToSemi
    
    endMatch(4005,"Casey Davis")
    endMatch(4004,"Ethan Leapley")
  end

  def nineManBracketPoolOneOutrightWinnerGuyTwo
     
     endMatch(1002,"Guy8")
     endMatch(1003,"Guy5")
     endMatch(2002,"Guy2")
     endMatch(2003,"Guy8")
     endMatch(3002,"Guy5")
     endMatch(3003,"Guy2")
     endMatch(4002,"Guy8")
     endMatch(4003,"Guy2")
     endMatch(5002,"Guy2")
     endMatch(5003,"Guy10")
  end
  
  def nineManBracketPoolTwoGuyNineHeadToHead
    
    endMatch(1004,"Guy4")
    endMatch(1005,"Guy3")
    endMatch(2004,"Guy9")
    endMatch(2005,"Guy7")
    endMatch(3004,"Guy9")
    endMatch(3005,"Guy3")
  end
  
  def nineManBracketPoolTwoGuyThreeHeadToHead
    
    endMatch(1004,"Guy9")
    endMatch(1005,"Guy3")
    endMatch(2004,"Guy3")
    endMatch(2005,"Guy7")
    endMatch(3004,"Guy9")
    endMatch(3005,"Guy4")
  end
  
  def nineManBracketPoolTwoGuyThreeDeductedPoints
    
    endMatch(1004,"Guy9")
    endMatch(1005,"Guy7")
    endMatch(2004,"Guy3")
    endMatch(2005,"Guy7")
    endMatch(3004,"Guy9")
    endMatch(3005,"Guy3")
    deduct = Teampointadjust.new
    deduct.wrestler_id = translateNameToId("Guy7")
    deduct.points = 1
    deduct.save
  end
  
  def nineManBracketPoolTwoGuyThreeMostDecisionPoints
    
    endMatchExtraPoints(1004,"Guy9")
    endMatch(1005,"Guy7")
    endMatchExtraPoints(2004,"Guy3")
    endMatch(2005,"Guy7")
    endMatch(3004,"Guy9")
    endMatchExtraPoints(3005,"Guy3")
  end
  
  def nineManBracketPoolTwoGuyThreeQuickestPin
    
    endMatchWithQuickPin(1004,"Guy9")
    endMatchWithPin(1005,"Guy7")
    endMatchWithQuickPin(2004,"Guy3")
    endMatchWithPin(2005,"Guy7")
    endMatchWithPin(3004,"Guy9")
    endMatchWithQuickestPin(3005,"Guy3")
  end
  
  def nineManBracketPoolTwoGuyThreeTeamPoints
    
    endMatch(1004,"Guy9")
    endMatch(1005,"Guy7")
    endMatchWithMajor(2004,"Guy3")
    endMatch(2005,"Guy7")
    endMatch(3004,"Guy9")
    endMatch(3005,"Guy3")
  end
  
  def nineManBracketPoolTwoGuyThreeMostPins
    
    endMatchWithMajor(1004,"Guy9")
    endMatch(1005,"Guy7")
    endMatchWithPin(2004,"Guy3")
    endMatchWithMajor(2005,"Guy7")
    endMatch(3004,"Guy9")
    endMatch(3005,"Guy3")
  end
  
  def nineManBracketPoolOneGuyEightMostTechs
    
    endMatchWithTech(1002,"Guy8")
    endMatch(1003,"Guy5")
    endMatchWithMajor(2002,"Guy2")
    endMatchWithTech(2003,"Guy8")
    endMatchWithMajor(3002,"Guy10")
    endMatchWithMajor(3003,"Guy2")
    endMatch(4002,"Guy8")
    endMatchWithMajor(4003,"Guy10")
    endMatchWithMajor(5002,"Guy2")
    endMatchWithMajor(5003,"Guy10")
  end
  
  def elevenManBracketToQuarter
    
    endMatch(1009,"Guy11")
    endMatch(2009,"Guy11")
    endMatch(3009,"Guy18")
    endMatch(1010,"Guy12")
    endMatch(2010,"Guy12")
    endMatch(3010,"Guy17")
    endMatch(1011,"Guy13")
    endMatch(2011,"Guy13")
    endMatch(3011,"Guy19")
    endMatch(1012,"Guy14")
  end
  def elevenManBracketToSemis
    elevenManBracketToQuarter
    
    endMatch(4006,"Guy11")
    endMatch(4007,"Guy14")
    endMatch(4008,"Guy12")
    endMatch(4009,"Guy13")
  end
  
  def elevenManBracketToFinals
    elevenManBracketToSemis
    
    endMatch(5004,"Guy11")
    endMatch(5005,"Guy12")
    endMatch(5006,"Guy17")
    endMatch(5007,"Guy18")
  end
  
  def elevenManBracketFinished
    elevenManBracketToFinals
    
    endMatch(6004,"Guy11")
    endMatch(6005,"Guy14")
    endMatch(6006,"Guy17")
    endMatch(6007,"Guy19")
  end
  
  def extraDoesNotScoreTeamPoints
    
    wrestlerName = "Guy22"
    wrestler = Wrestler.find(translateNameToId(wrestlerName))
    wrestler.extra = true
    wrestler.save
    endMatch(1013,"Guy22")
  end
  
  def endMatch(bout,winner)
     match = Match.where(bout_number: bout).first
     match.win_type = "Decision"
     match.score = 1-0
     saveMatch(match,winner)
  end
  
  def endMatchExtraPoints(bout,winner)
     match = Match.where(bout_number: bout).first
     match.win_type = "Decision"
     match.score = 0-2
     saveMatch(match,winner)
  end
  
  def endMatchWithMajor(bout,winner)
     match = Match.where(bout_number: bout).first
     match.win_type = "Major"
     match.score = 8-0
     saveMatch(match,winner)
  end
  
  def endMatchWithTech(bout,winner)
     match = Match.where(bout_number: bout).first
     match.win_type = "Tech Fall"
     match.score = 15-0
     saveMatch(match,winner)
  end
  
  def endMatchWithPin(bout,winner)
     match = Match.where(bout_number: bout).first
     match.win_type = "Pin"
     match.score = "5:00"
     saveMatch(match,winner)
  end
  
  def endMatchWithQuickestPin(bout,winner)
     match = Match.where(bout_number: bout).first
     match.win_type = "Pin"
     match.score = "0:20"
     saveMatch(match,winner)
  end
  
  def endMatchWithQuickPin(bout,winner)
     match = Match.where(bout_number: bout).first
     match.win_type = "Pin"
     match.score = "1:20"
     saveMatch(match,winner)
  end
  
  def saveMatch(match,winner)
    match.finished = 1
    match.winner_id = translateNameToId(winner)
    
    match.save!
    # match.after_update_actions
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
    assert_equal 22, wrestler1.totalTeamPoints
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
    wrestler = Wrestler.where("name = ?", "Guy17").first

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
    endMatch(6000,"Guy2")
    wrestler1 = Wrestler.where("name = ?", "Guy2").first
    assert_equal 16, wrestler1.placementPoints
  end
  
  test "advancement points winner 3/4" do
    nineManBracketPoolOneOutrightWinnerGuyTwo
    nineManBracketPoolTwoGuyThreeHeadToHead
    endMatch(6001,"Guy8")
    wrestler1 = Wrestler.where("name = ?", "Guy8").first
    assert_equal 10, wrestler1.placementPoints
  end
  
  test "advancement points winner 5/6" do
    elevenManBracketFinished
    wrestler = Wrestler.where("name = ?", "Guy17").first

    assert_equal 7, wrestler.placementPoints
  end
  
  test "advancement points winner 7/8" do
    elevenManBracketFinished
    wrestler = Wrestler.where("name = ?", "Guy19").first

    assert_equal 4, wrestler.placementPoints
  end
  
  test "bonus points major" do
    endMatchWithMajor(2002,"Guy2")
    wrestler1 = Wrestler.where("name = ?", "Guy2").first
    assert_equal 5, wrestler1.teamPointsEarned
  end
  
  test "bonus points pin" do
    endMatchWithPin(2002,"Guy2")
    wrestler1 = Wrestler.where("name = ?", "Guy2").first
    assert_equal 6, wrestler1.teamPointsEarned
  end
  
  test "bonus points tech fall" do
    endMatchWithTech(2002,"Guy2")
    wrestler1 = Wrestler.where("name = ?", "Guy2").first
    assert_equal 5.5, wrestler1.teamPointsEarned
  end
  
  test "pool team points win" do
    endMatch(2002,"Guy2")
    wrestler1 = Wrestler.where("name = ?", "Guy2").first
    assert_equal 4, wrestler1.teamPointsEarned
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
    mat2 = Mat.new
    mat2.name = "2"
    mat2.tournament_id = 1
    mat2.save
    assert_equal 4, mat2.matches.size
    elevenManBracketFinished
    mat2.destroy
    mat1 = Mat.find(1)
    assert_equal 4, mat1.matches.size
  end
  
  test "Championship bracket wins are 2pts" do
    elevenManBracketToQuarter
    assert_equal 7, Wrestler.where("name = ?", "Guy11").first.teamPointsEarned
    
    endMatch(4006,"Guy11")
    assert_equal 15, Wrestler.where("name = ?", "Guy11").first.teamPointsEarned
    endMatch(4007,"Guy14")
    endMatch(5004,"Guy11")
    assert_equal 20, Wrestler.where("name = ?", "Guy11").first.teamPointsEarned
  end
  
  test "Conso bracket wins are 1pt" do
    elevenManBracketToSemis
    assert_equal 7, Wrestler.where("name = ?", "Guy17").first.teamPointsEarned
    
    endMatch(5006,"Guy17")
    assert_equal 11, Wrestler.where("name = ?", "Guy17").first.teamPointsEarned
  end
  
  test "One pool placement points" do
    singlePoolFinished
    wrestler1 = Wrestler.where("name = ?", "James Wimer").first
    wrestler2 = Wrestler.where("name = ?", "Jaden Mattox").first
    wrestler3 = Wrestler.where("name = ?", "Jackson Lakso").first
    wrestler4 = Wrestler.where("name = ?", "JD Woods").first
    assert_equal 16, wrestler1.placementPoints
    assert_equal 12, wrestler2.placementPoints
    assert_equal 10, wrestler3.placementPoints
    assert_equal 9, wrestler4.placementPoints
  end
  
  test "One pool placement points zero if pool not finished" do
    singlePoolNotFinished
    wrestler1 = Wrestler.where("name = ?", "James Wimer").first
    assert_equal 0, wrestler1.placementPoints
  end
  
  
  
end
