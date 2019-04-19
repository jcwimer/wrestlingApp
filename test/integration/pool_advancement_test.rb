require 'test_helper'

class PoolAdvancementTest < ActionDispatch::IntegrationTest

  def setup
    
  end
  
  

  # test "nine man outright finals advance" do
  #   nineManBracketPoolOneOutrightWinnerGuyTwo
  #   wrestler = Wrestler.where("name = ?", "Guy2").first
  #   assert_equal 6000, wrestler.bout_by_round(6)
  # end

  # test "nine man outright conso finals advance" do
  #   nineManBracketPoolOneOutrightWinnerGuyTwo
  #   wrestler = Wrestler.where("name = ?", "Guy8").first
  #   assert_equal 6001, wrestler.bout_by_round(6)
  # end

  # test "nine man pool 2 man to man tie breaker finalist guy 9" do
  #   wrestler = Wrestler.where("name = ?", "Guy9").first
  #   nineManBracketPoolTwoGuyNineHeadToHead
  #   assert_equal 6000, wrestler.bout_by_round(6)
  # end
  
  # test "nine man pool 2 man to man tie breaker finalist guy 3" do
  #   wrestler = Wrestler.where("name = ?", "Guy3").first
  #   nineManBracketPoolTwoGuyThreeHeadToHead
  #   assert_equal 6000, wrestler.bout_by_round(6)
  # end
  
  # test "nine man conso finals man to man tie breaker guy 3" do
  #   nineManBracketPoolTwoGuyNineHeadToHead
  #   wrestler = Wrestler.where("name = ?", "Guy3").first
  #   assert_equal 6001, wrestler.bout_by_round(6)
  # end
  
  # test "nine man conso finals man to man tie breaker guy 9" do
  #   nineManBracketPoolTwoGuyThreeHeadToHead
  #   wrestler = Wrestler.where("name = ?", "Guy9").first
  #   assert_equal 6001, wrestler.bout_by_round(6)
  # end
  
  # test "nine man pool 2 deductedPoints tie breaker finalist guy 3" do
  #   wrestler = Wrestler.where("name = ?", "Guy3").first
  #   nineManBracketPoolTwoGuyThreeDeductedPoints
  #   assert_equal 6000, wrestler.bout_by_round(6)
  # end
  
  # test "nine man conso finals deductedPoints tie breaker guy 9" do
  #   nineManBracketPoolTwoGuyThreeDeductedPoints
  #   wrestler = Wrestler.where("name = ?", "Guy9").first
  #   assert_equal 6001, wrestler.bout_by_round(6)
  # end
  
  
  
  # test "nine man pool 2 mostDecisionPointsScored tie breaker finalist guy 3" do
  #   wrestler = Wrestler.where("name = ?", "Guy3").first
  #   nineManBracketPoolTwoGuyThreeMostDecisionPoints
  #   assert_equal 6000, wrestler.bout_by_round(6)
  # end
  
  # test "nine man conso finals mostDecisionPointsScored tie breaker guy 9" do
  #   nineManBracketPoolTwoGuyThreeMostDecisionPoints
  #   wrestler = Wrestler.where("name = ?", "Guy9").first
  #   assert_equal 6001, wrestler.bout_by_round(6)
  # end
  
  # test "nine man pool 2 QuickestPin tie breaker finalist guy 3" do
  #   wrestler = Wrestler.where("name = ?", "Guy3").first
  #   nineManBracketPoolTwoGuyThreeQuickestPin
  #   assert_equal 6000, wrestler.bout_by_round(6)
  # end
  
  # test "nine man conso finals QuickestPin tie breaker guy 9" do
  #   nineManBracketPoolTwoGuyThreeQuickestPin
  #   wrestler = Wrestler.where("name = ?", "Guy9").first
  #   assert_equal 6001, wrestler.bout_by_round(6)
  # end
  
  # test "nine man pool 2 teamPoints tie breaker finalist guy 3" do
  #   wrestler = Wrestler.where("name = ?", "Guy3").first
  #   nineManBracketPoolTwoGuyThreeTeamPoints
  #   assert_equal 6000, wrestler.bout_by_round(6)
  # end
  
  # test "nine man conso finals teamPoints tie breaker guy 9" do
  #   nineManBracketPoolTwoGuyThreeTeamPoints
  #   wrestler = Wrestler.where("name = ?", "Guy9").first
  #   assert_equal 6001, wrestler.bout_by_round(6)
  # end
  
  # test "nine man pool 2 mostPins tie breaker finalist guy 3" do
  #   wrestler = Wrestler.where("name = ?", "Guy3").first
  #   nineManBracketPoolTwoGuyThreeMostPins
  #   assert_equal 6000, wrestler.bout_by_round(6)
  # end
  
  # test "nine man conso finals mostPins tie breaker guy 9" do
  #   nineManBracketPoolTwoGuyThreeMostPins
  #   wrestler = Wrestler.where("name = ?", "Guy9").first
  #   assert_equal 6001, wrestler.bout_by_round(6)
  # end
  
  # test "nine man pool 1 mostTechs tie breaker finalist guy 8" do
  #   nineManBracketPoolOneGuyEightMostTechs
  #   wrestler = Wrestler.where("name = ?", "Guy8").first
  #   assert_equal 6000, wrestler.bout_by_round(6)
  # end
  
  # test "nine man conso finals mostTechs tie breaker guy 10" do
  #   nineManBracketPoolOneGuyEightMostTechs
  #   wrestler = Wrestler.where("name = ?", "Guy10").first
  #   assert_equal 6001, wrestler.bout_by_round(6)
  # end
  
  # test "twoPoolsToFinal total points finals" do
  #   nineManBracketPoolOneOutrightWinnerGuyTwo
  #   nineManBracketPoolTwoGuyThreeHeadToHead
  #   wrestler1 = Wrestler.where("name = ?", "Guy2").first
  #   wrestler2 = Wrestler.where("name = ?", "Guy3").first
  #   #Won four in pool
  #   assert_equal 22, wrestler1.total_team_points
  #   #Won two in pool
  #   assert_equal 18, wrestler2.total_team_points
  # end
  
  # test "advancement points 1/2" do
  #   nineManBracketPoolOneOutrightWinnerGuyTwo
  #   wrestler1 = Wrestler.where("name = ?", "Guy2").first
  #   assert_equal 12, wrestler1.placement_points
  # end
  
  # test "advancement points 3/4" do
  #   nineManBracketPoolOneOutrightWinnerGuyTwo
  #   wrestler1 = Wrestler.where("name = ?", "Guy8").first
  #   assert_equal 9, wrestler1.placement_points
  # end
  
  # test "advancement points 5/6" do
  #   elevenManBracketToFinals
  #   wrestler = Wrestler.where("name = ?", "Guy17").first

  #   assert_equal 6, wrestler.placement_points
  # end
  
  # test "advancement points 7/8" do
  #   elevenManBracketToFinals
  #   wrestler = Wrestler.where("name = ?", "Guy19").first

  #   assert_equal 3, wrestler.placement_points
  # end
  
  # test "advancement points winner 1/2" do
  #   nineManBracketPoolOneOutrightWinnerGuyTwo
  #   nineManBracketPoolTwoGuyThreeHeadToHead
  #   endMatch(6000,"Guy2")
  #   wrestler1 = Wrestler.where("name = ?", "Guy2").first
  #   assert_equal 16, wrestler1.placement_points
  # end
  
  # test "advancement points winner 3/4" do
  #   nineManBracketPoolOneOutrightWinnerGuyTwo
  #   nineManBracketPoolTwoGuyThreeHeadToHead
  #   endMatch(6001,"Guy8")
  #   wrestler1 = Wrestler.where("name = ?", "Guy8").first
  #   assert_equal 10, wrestler1.placement_points
  # end
  
  # test "advancement points winner 5/6" do
  #   elevenManBracketFinished
  #   wrestler = Wrestler.where("name = ?", "Guy17").first

  #   assert_equal 7, wrestler.placement_points
  # end
  
  # test "advancement points winner 7/8" do
  #   elevenManBracketFinished
  #   wrestler = Wrestler.where("name = ?", "Guy19").first

  #   assert_equal 4, wrestler.placement_points
  # end
  
  # test "bonus points major" do
  #   endMatchWithMajor(2002,"Guy2")
  #   wrestler1 = Wrestler.where("name = ?", "Guy2").first
  #   assert_equal 5, wrestler1.team_points_earned
  # end
  
  # test "bonus points pin" do
  #   endMatchWithPin(2002,"Guy2")
  #   wrestler1 = Wrestler.where("name = ?", "Guy2").first
  #   assert_equal 6, wrestler1.team_points_earned
  # end
  
  # test "bonus points tech fall" do
  #   endMatchWithTech(2002,"Guy2")
  #   wrestler1 = Wrestler.where("name = ?", "Guy2").first
  #   assert_equal 5.5, wrestler1.team_points_earned
  # end
  
  # test "pool team points win" do
  #   endMatch(2002,"Guy2")
  #   wrestler1 = Wrestler.where("name = ?", "Guy2").first
  #   assert_equal 4, wrestler1.team_points_earned
  # end
  
  # test "advancement points fourPoolsToQuarter Quarter" do
  #   elevenManBracketToQuarter
  #   wrestler1 = Wrestler.where("name = ?", "Guy11").first
  #   assert_equal 3, wrestler1.placement_points
  # end
  
  # test "advancement points fourPoolsToQuarter Semis" do
  #   elevenManBracketToSemis
  #   wrestler = Wrestler.where("name = ?", "Guy11").first

  #   assert_equal 9, wrestler.placement_points
  # end
  
  # test "advancement points twoPoolsToSemi Semis" do
  #   sevenManTwoPoolToSemi
  #   wrestler = Wrestler.where("name = ?", "Casey Davis").first

  #   assert_equal 9, wrestler.placement_points
  # end
  
  # test "advancement points twoPoolsToSemi Finals" do
  #   sevenManTwoPoolSemiToFinals
  #   wrestler = Wrestler.where("name = ?", "Casey Davis").first

  #   assert_equal 12, wrestler.placement_points
  # end
  
  # test "advancement points fourPoolsToSemi Semis and Conso Semis" do
  #   sixteenManToSemi
  #   wrestler = Wrestler.where("name = ?", "Guy22").first

  #   assert_equal 9, wrestler.placement_points
    
  #   wrestler = Wrestler.where("name = ?", "Guy29").first

  #   assert_equal 3, wrestler.placement_points
  # end
  
  # test "extra does not score points but does get pool criteria" do
  #   extraDoesNotScoreTeamPoints
  #   wrestler = Wrestler.where("name = ?", "Guy22").first
    
  #   assert_equal 0, wrestler.total_team_points
  #   assert_equal 2, wrestler.team_points_earned
  # end
    
  # test "Test mat assignment when adding a mat and when destroying a mat" do
  #   mat2 = Mat.new
  #   mat2.name = "2"
  #   mat2.tournament_id = 1
  #   mat2.save
  #   assert_equal 4, mat2.matches.size
  #   elevenManBracketFinished
  #   mat2.destroy
  #   mat1 = Mat.find(1)
  #   assert_equal 4, mat1.matches.size
  # end
  
  # test "Championship bracket wins are 2pts" do
  #   elevenManBracketToQuarter
  #   assert_equal 9, Wrestler.where("name = ?", "Guy11").first.team_points_earned
    
  #   endMatch(4006,"Guy11")
  #   assert_equal 17, Wrestler.where("name = ?", "Guy11").first.team_points_earned
  #   endMatch(4007,"Guy14")
  #   endMatch(5004,"Guy11")
  #   assert_equal 22, Wrestler.where("name = ?", "Guy11").first.team_points_earned
  # end
  
  # test "Conso bracket wins are 1pt" do
  #   elevenManBracketToSemis
  #   assert_equal 7, Wrestler.where("name = ?", "Guy17").first.team_points_earned
    
  #   endMatch(5006,"Guy17")
  #   assert_equal 11, Wrestler.where("name = ?", "Guy17").first.team_points_earned
  # end
  
  # test "One pool placement points" do
  #   singlePoolFinished
  #   wrestler1 = Wrestler.where("name = ?", "James Wimer").first
  #   wrestler2 = Wrestler.where("name = ?", "Jaden Mattox").first
  #   wrestler3 = Wrestler.where("name = ?", "Jackson Lakso").first
  #   wrestler4 = Wrestler.where("name = ?", "JD Woods").first
  #   assert_equal 16, wrestler1.placement_points
  #   assert_equal 12, wrestler2.placement_points
  #   assert_equal 10, wrestler3.placement_points
  #   assert_equal 9, wrestler4.placement_points
  # end
  
  # test "One pool placement points zero if pool not finished" do
  #   singlePoolNotFinished
  #   wrestler1 = Wrestler.where("name = ?", "James Wimer").first
  #   assert_equal 0, wrestler1.placement_points
  # end
  
  
  
end
