require 'test_helper'

class PoolAdvancementTest < ActionDispatch::IntegrationTest

  def setup
    create_pool_tournament_single_weight(6)
  end

  def finishWithNoTies
    end_match(match_wrestler_vs("Test1","Test2"),"Test1")
    end_match(match_wrestler_vs("Test1","Test3"),"Test1")
    end_match(match_wrestler_vs("Test1","Test4"),"Test1")
    end_match(match_wrestler_vs("Test1","Test5"),"Test1")
    end_match(match_wrestler_vs("Test1","Test6"),"Test1")
    end_match(match_wrestler_vs("Test2","Test3"),"Test2")
    end_match(match_wrestler_vs("Test2","Test4"),"Test2")
    end_match(match_wrestler_vs("Test2","Test5"),"Test2")
    end_match(match_wrestler_vs("Test2","Test6"),"Test2")
    end_match(match_wrestler_vs("Test3","Test4"),"Test3")
    end_match(match_wrestler_vs("Test3","Test5"),"Test3")
    end_match(match_wrestler_vs("Test3","Test6"),"Test3")
    end_match(match_wrestler_vs("Test4","Test5"),"Test4")
    end_match(match_wrestler_vs("Test4","Test6"),"Test4")
    end_match(match_wrestler_vs("Test5","Test6"),"Test5")
  end

  def finishNonTiebreakerMatches
    @tournament.matches.where("w1 = ? OR w2 = ? AND w1 != ? OR w2 != ? AND w1 != ? OR w2 != ?",translate_name_to_id("Test1"),translate_name_to_id("Test1"),translate_name_to_id("Test2"),translate_name_to_id("Test2"),translate_name_to_id("Test3"),translate_name_to_id("Test3")).each do | match |
    	end_match(match,"Test1")
    end
    @tournament.matches.where("w1 = ? OR w2 = ? AND w1 != ? OR w2 != ? AND w1 != ? OR w2 != ?",translate_name_to_id("Test2"),translate_name_to_id("Test2"),translate_name_to_id("Test1"),translate_name_to_id("Test1"),translate_name_to_id("Test3"),translate_name_to_id("Test3")).each do | match |
    	end_match(match,"Test1")
    end
    @tournament.matches.where("w1 = ? OR w2 = ? AND w1 != ? OR w2 != ? AND w1 != ? OR w2 != ?",translate_name_to_id("Test3"),translate_name_to_id("Test3"),translate_name_to_id("Test1"),translate_name_to_id("Test1"),translate_name_to_id("Test2"),translate_name_to_id("Test2")).each do | match |
    	end_match(match,"Test1")
    end
    @tournament.matches.where("w1 = ? OR w2 = ? AND finished != 1",translate_name_to_id("Test4"),translate_name_to_id("Test4")).each do | match |
    	end_match(match,"Test4")
    end
    @tournament.matches.where("w1 = ? OR w2 = ? AND finished != 1",translate_name_to_id("Test5"),translate_name_to_id("Test5")).each do | match |
    	end_match(match,"Test5")
    end
    @tournament.matches.where("w1 = ? OR w2 = ? AND finished != 1",translate_name_to_id("Test6"),translate_name_to_id("Test6")).each do | match |
    	end_match(match,"Test6")
    end
  end

  def finishWithTieMostTeamPoints
    end_match_with_pin(match_wrestler_vs("Test1","Test2"),"Test1")
    end_match(match_wrestler_vs("Test1","Test3"),"Test3")
    end_match(match_wrestler_vs("Test1","Test4"),"Test1")
    end_match(match_wrestler_vs("Test1","Test5"),"Test1")
    end_match(match_wrestler_vs("Test1","Test6"),"Test1")
    end_match(match_wrestler_vs("Test2","Test3"),"Test2")
    end_match(match_wrestler_vs("Test2","Test4"),"Test2")
    end_match(match_wrestler_vs("Test2","Test5"),"Test2")
    end_match(match_wrestler_vs("Test2","Test6"),"Test2")
    end_match(match_wrestler_vs("Test3","Test4"),"Test3")
    end_match(match_wrestler_vs("Test3","Test5"),"Test3")
    end_match(match_wrestler_vs("Test3","Test6"),"Test3")
    end_match(match_wrestler_vs("Test4","Test5"),"Test4")
    end_match(match_wrestler_vs("Test4","Test6"),"Test4")
    end_match(match_wrestler_vs("Test5","Test6"),"Test5")    	
  end

  def finishWithTieMostTeamPointsSecondPlace
    end_match(match_wrestler_vs("Test1","Test2"),"Test1")
    end_match(match_wrestler_vs("Test1","Test3"),"Test1")
    end_match(match_wrestler_vs("Test1","Test4"),"Test1")
    end_match(match_wrestler_vs("Test1","Test5"),"Test1")
    end_match(match_wrestler_vs("Test1","Test6"),"Test1")
    end_match_with_pin(match_wrestler_vs("Test2","Test3"),"Test2")
    end_match(match_wrestler_vs("Test2","Test4"),"Test4")
    end_match(match_wrestler_vs("Test2","Test5"),"Test2")
    end_match(match_wrestler_vs("Test2","Test6"),"Test2")
    end_match(match_wrestler_vs("Test3","Test4"),"Test3")
    end_match(match_wrestler_vs("Test3","Test5"),"Test3")
    end_match(match_wrestler_vs("Test3","Test6"),"Test3")
    end_match(match_wrestler_vs("Test4","Test5"),"Test4")
    end_match(match_wrestler_vs("Test4","Test6"),"Test4")
    end_match(match_wrestler_vs("Test5","Test6"),"Test5")       
  end

  def finishWithTieMostTeamPointsTwoWayTie
    end_match_with_pin(match_wrestler_vs("Test1","Test2"),"Test1")
    end_match_with_pin(match_wrestler_vs("Test1","Test3"),"Test3")
    end_match(match_wrestler_vs("Test1","Test4"),"Test1")
    end_match(match_wrestler_vs("Test1","Test5"),"Test1")
    end_match(match_wrestler_vs("Test1","Test6"),"Test1")
    end_match(match_wrestler_vs("Test2","Test3"),"Test2")
    end_match(match_wrestler_vs("Test2","Test4"),"Test2")
    end_match(match_wrestler_vs("Test2","Test5"),"Test2")
    end_match(match_wrestler_vs("Test2","Test6"),"Test2")
    end_match(match_wrestler_vs("Test3","Test4"),"Test3")
    end_match(match_wrestler_vs("Test3","Test5"),"Test3")
    end_match(match_wrestler_vs("Test3","Test6"),"Test3")
    end_match(match_wrestler_vs("Test4","Test5"),"Test4")
    end_match(match_wrestler_vs("Test4","Test6"),"Test4")
    end_match(match_wrestler_vs("Test5","Test6"),"Test5")       
  end

  def finishedWithTieMostFalls
    #Test1 has 12 points
    #Test2 has 12 points
    #Test3 has 12 points

    end_match_with_pin(match_wrestler_vs("Test1","Test2"),"Test1")
    end_match_with_major(match_wrestler_vs("Test1","Test3"),"Test3")
    end_match(match_wrestler_vs("Test1","Test4"),"Test1")
    end_match(match_wrestler_vs("Test1","Test5"),"Test1")
    end_match_with_pin(match_wrestler_vs("Test1","Test6"),"Test1")
    end_match_with_major(match_wrestler_vs("Test2","Test3"),"Test2")
    end_match_with_major(match_wrestler_vs("Test2","Test4"),"Test2")
    end_match_with_major(match_wrestler_vs("Test2","Test5"),"Test2")
    end_match_with_major(match_wrestler_vs("Test2","Test6"),"Test2")
    end_match_with_major(match_wrestler_vs("Test3","Test4"),"Test3")
    end_match_with_major(match_wrestler_vs("Test3","Test5"),"Test3")
    end_match_with_major(match_wrestler_vs("Test3","Test6"),"Test3")
    end_match(match_wrestler_vs("Test4","Test5"),"Test4")
    end_match(match_wrestler_vs("Test4","Test6"),"Test4")
    end_match(match_wrestler_vs("Test5","Test6"),"Test5") 
  end

  def finishedWithTieMostTechFalls
    #Test1 has 11 points
    #Test2 has 11 points
    #Test3 has 11 points

    end_match_with_tech(match_wrestler_vs("Test1","Test2"),"Test1")
    end_match(match_wrestler_vs("Test1","Test3"),"Test3")
    end_match(match_wrestler_vs("Test1","Test4"),"Test1")
    end_match(match_wrestler_vs("Test1","Test5"),"Test1")
    end_match_with_tech(match_wrestler_vs("Test1","Test6"),"Test1")
    end_match(match_wrestler_vs("Test2","Test3"),"Test2")
    end_match_with_major(match_wrestler_vs("Test2","Test4"),"Test2")
    end_match_with_major(match_wrestler_vs("Test2","Test5"),"Test2")
    end_match_with_major(match_wrestler_vs("Test2","Test6"),"Test2")
    end_match_with_major(match_wrestler_vs("Test3","Test4"),"Test3")
    end_match_with_major(match_wrestler_vs("Test3","Test5"),"Test3")
    end_match_with_major(match_wrestler_vs("Test3","Test6"),"Test3")
    end_match(match_wrestler_vs("Test4","Test5"),"Test4")
    end_match(match_wrestler_vs("Test4","Test6"),"Test4")
    end_match(match_wrestler_vs("Test5","Test6"),"Test5")
  end

  def finishedWithTieQuickestPin
    #Test1 has 5:20 of pin time
    #Test2 has 9:20 of pin time
    #Test3 has 20 minutes of pin time

    end_match_with_pin(match_wrestler_vs("Test1","Test2"),"Test1")
    end_match_with_pin(match_wrestler_vs("Test1","Test3"),"Test3")
    end_match_with_quick_pin(match_wrestler_vs("Test1","Test4"),"Test1")
    end_match_with_quick_pin(match_wrestler_vs("Test1","Test5"),"Test1")
    end_match_with_quick_pin(match_wrestler_vs("Test1","Test6"),"Test1")
    end_match_with_pin(match_wrestler_vs("Test2","Test3"),"Test2")
    end_match_with_quick_pin(match_wrestler_vs("Test2","Test4"),"Test2")
    end_match_with_quick_pin(match_wrestler_vs("Test2","Test5"),"Test2")
    end_match_with_quick_pin(match_wrestler_vs("Test2","Test6"),"Test2")
    end_match(match_wrestler_vs("Test3","Test4"),"Test3")
    end_match_with_pin(match_wrestler_vs("Test3","Test5"),"Test3")
    end_match_with_pin(match_wrestler_vs("Test3","Test6"),"Test3")
    end_match(match_wrestler_vs("Test4","Test5"),"Test4")
    end_match(match_wrestler_vs("Test4","Test6"),"Test4")
    end_match(match_wrestler_vs("Test5","Test6"),"Test5") 
  end

  def finishedWithTieQuickestPinTwoWayTie
    #Test1 has 5:20 of pin time
    #Test2 has 9:20 of pin time
    #Test3 has 5:20 of pin time

    end_match_with_pin(match_wrestler_vs("Test1","Test2"),"Test1")
    end_match_with_pin(match_wrestler_vs("Test1","Test3"),"Test3")
    end_match_with_quick_pin(match_wrestler_vs("Test1","Test4"),"Test1")
    end_match_with_quick_pin(match_wrestler_vs("Test1","Test5"),"Test1")
    end_match_with_quick_pin(match_wrestler_vs("Test1","Test6"),"Test1")
    end_match_with_pin(match_wrestler_vs("Test2","Test3"),"Test2")
    end_match_with_quick_pin(match_wrestler_vs("Test2","Test4"),"Test2")
    end_match_with_quick_pin(match_wrestler_vs("Test2","Test5"),"Test2")
    end_match_with_quick_pin(match_wrestler_vs("Test2","Test6"),"Test2")
    end_match_with_quick_pin(match_wrestler_vs("Test3","Test4"),"Test3")
    end_match_with_quick_pin(match_wrestler_vs("Test3","Test5"),"Test3")
    end_match_with_quick_pin(match_wrestler_vs("Test3","Test6"),"Test3")
    end_match(match_wrestler_vs("Test4","Test5"),"Test4")
    end_match(match_wrestler_vs("Test4","Test6"),"Test4")
    end_match(match_wrestler_vs("Test5","Test6"),"Test5") 
  end

  def finishedWithTieCoinFlip
    end_match(match_wrestler_vs("Test1","Test2"),"Test1")
    end_match(match_wrestler_vs("Test1","Test3"),"Test3")
    end_match(match_wrestler_vs("Test1","Test4"),"Test1")
    end_match(match_wrestler_vs("Test1","Test5"),"Test1")
    end_match(match_wrestler_vs("Test1","Test6"),"Test1")
    end_match(match_wrestler_vs("Test2","Test3"),"Test2")
    end_match(match_wrestler_vs("Test2","Test4"),"Test2")
    end_match(match_wrestler_vs("Test2","Test5"),"Test2")
    end_match(match_wrestler_vs("Test2","Test6"),"Test2")
    end_match(match_wrestler_vs("Test3","Test4"),"Test3")
    end_match(match_wrestler_vs("Test3","Test5"),"Test3")
    end_match(match_wrestler_vs("Test3","Test6"),"Test3")
    end_match(match_wrestler_vs("Test4","Test5"),"Test4")
    end_match(match_wrestler_vs("Test4","Test6"),"Test4")
    end_match(match_wrestler_vs("Test5","Test6"),"Test5") 
  end

  def finishedWithDeductedPoints
    team_point_adjusts_for_wrestler("Test2", 1)
    team_point_adjusts_for_wrestler("Test3", 2)

    end_match(match_wrestler_vs("Test1","Test2"),"Test1")
    end_match(match_wrestler_vs("Test1","Test3"),"Test3")
    end_match(match_wrestler_vs("Test1","Test4"),"Test1")
    end_match(match_wrestler_vs("Test1","Test5"),"Test1")
    end_match(match_wrestler_vs("Test1","Test6"),"Test1")
    end_match(match_wrestler_vs("Test2","Test3"),"Test2")
    end_match(match_wrestler_vs("Test2","Test4"),"Test2")
    end_match(match_wrestler_vs("Test2","Test5"),"Test2")
    end_match(match_wrestler_vs("Test2","Test6"),"Test2")
    end_match(match_wrestler_vs("Test3","Test4"),"Test3")
    end_match(match_wrestler_vs("Test3","Test5"),"Test3")
    end_match(match_wrestler_vs("Test3","Test6"),"Test3")
    end_match(match_wrestler_vs("Test4","Test5"),"Test4")
    end_match(match_wrestler_vs("Test4","Test6"),"Test4")
    end_match(match_wrestler_vs("Test5","Test6"),"Test5") 
  end

  def finishedWithDeductedPointsTwoWayTie
    team_point_adjusts_for_wrestler("Test1", 2)
    team_point_adjusts_for_wrestler("Test2", 1)
    team_point_adjusts_for_wrestler("Test3", 1)

    end_match(match_wrestler_vs("Test1","Test2"),"Test1")
    end_match(match_wrestler_vs("Test1","Test3"),"Test3")
    end_match(match_wrestler_vs("Test1","Test4"),"Test1")
    end_match(match_wrestler_vs("Test1","Test5"),"Test1")
    end_match(match_wrestler_vs("Test1","Test6"),"Test1")
    end_match(match_wrestler_vs("Test2","Test3"),"Test2")
    end_match(match_wrestler_vs("Test2","Test4"),"Test2")
    end_match(match_wrestler_vs("Test2","Test5"),"Test2")
    end_match(match_wrestler_vs("Test2","Test6"),"Test2")
    end_match(match_wrestler_vs("Test3","Test4"),"Test3")
    end_match(match_wrestler_vs("Test3","Test5"),"Test3")
    end_match(match_wrestler_vs("Test3","Test6"),"Test3")
    end_match(match_wrestler_vs("Test4","Test5"),"Test4")
    end_match(match_wrestler_vs("Test4","Test6"),"Test4")
    end_match(match_wrestler_vs("Test5","Test6"),"Test5") 
  end

  def finishedWithDeductedPointsTwoWayTieWithZero
    team_point_adjusts_for_wrestler("Test1", 1)

    end_match(match_wrestler_vs("Test1","Test2"),"Test1")
    end_match(match_wrestler_vs("Test1","Test3"),"Test3")
    end_match(match_wrestler_vs("Test1","Test4"),"Test1")
    end_match(match_wrestler_vs("Test1","Test5"),"Test1")
    end_match(match_wrestler_vs("Test1","Test6"),"Test1")
    end_match(match_wrestler_vs("Test2","Test3"),"Test2")
    end_match(match_wrestler_vs("Test2","Test4"),"Test2")
    end_match(match_wrestler_vs("Test2","Test5"),"Test2")
    end_match(match_wrestler_vs("Test2","Test6"),"Test2")
    end_match(match_wrestler_vs("Test3","Test4"),"Test3")
    end_match(match_wrestler_vs("Test3","Test5"),"Test3")
    end_match(match_wrestler_vs("Test3","Test6"),"Test3")
    end_match(match_wrestler_vs("Test4","Test5"),"Test4")
    end_match(match_wrestler_vs("Test4","Test6"),"Test4")
    end_match(match_wrestler_vs("Test5","Test6"),"Test5") 
  end

  test "Pool order based on wins" do
  	finishWithNoTies
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement = 1
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement = 2
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement = 3
    assert Wrestler.find(translate_name_to_id("Test4")).pool_placement = 4
    assert Wrestler.find(translate_name_to_id("Test5")).pool_placement = 5
    assert Wrestler.find(translate_name_to_id("Test6")).pool_placement = 6
  end

  test "Pool order three way tie with most team points" do
  	finishWithTieMostTeamPoints
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement = 1
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement_tiebreaker = "Team Points"
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement = 2
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement_tiebreaker = "Head to Head"
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement = 3
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement_tiebreaker = ""
    assert Wrestler.find(translate_name_to_id("Test4")).pool_placement = 4
    assert Wrestler.find(translate_name_to_id("Test5")).pool_placement = 5
    assert Wrestler.find(translate_name_to_id("Test6")).pool_placement = 6
  end

  test "Pool order three way tie with most team points where first place won by wins" do
    finishWithTieMostTeamPointsSecondPlace
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement = 1
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement_tiebreaker = ""
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement = 2
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement_tiebreaker = "Team Points"
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement = 3
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement_tiebreaker = "Head to Head"
    assert Wrestler.find(translate_name_to_id("Test4")).pool_placement = 4
    assert Wrestler.find(translate_name_to_id("Test4")).pool_placement_tiebreaker = ""
    assert Wrestler.find(translate_name_to_id("Test5")).pool_placement = 5
    assert Wrestler.find(translate_name_to_id("Test6")).pool_placement = 6
  end

  test "Pool order three way tie with most team points but most team points are tied between two wrestlers" do
    finishWithTieMostTeamPointsTwoWayTie
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement = 2
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement_tiebreaker = "Team Points"
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement = 3
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement_tiebreaker = ""
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement = 1
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement_tiebreaker = "Head to Head"
    assert Wrestler.find(translate_name_to_id("Test4")).pool_placement = 4
    assert Wrestler.find(translate_name_to_id("Test5")).pool_placement = 5
    assert Wrestler.find(translate_name_to_id("Test6")).pool_placement = 6
  end

  test "Pool order three way tie with most pins" do
  	finishWithTieMostTeamPoints
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement = 1
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement_tiebreaker = "Most Pins"
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement = 2
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement_tiebreaker = "Head to Head"
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement = 3
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement_tiebreaker = ""
    assert Wrestler.find(translate_name_to_id("Test4")).pool_placement = 4
    assert Wrestler.find(translate_name_to_id("Test5")).pool_placement = 5
    assert Wrestler.find(translate_name_to_id("Test6")).pool_placement = 6
  end

  test "Pool order three way tie with most tech falls" do
  	finishWithTieMostTeamPoints
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement = 1
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement_tiebreaker = "Most Techs"
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement = 2
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement_tiebreaker = "Head to Head"
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement = 3
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement_tiebreaker = ""
    assert Wrestler.find(translate_name_to_id("Test4")).pool_placement = 4
    assert Wrestler.find(translate_name_to_id("Test5")).pool_placement = 5
    assert Wrestler.find(translate_name_to_id("Test6")).pool_placement = 6
  end

  test "Pool order three way tie with quickest pin times" do
  	finishedWithTieQuickestPin
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement = 1
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement_tiebreaker = "Pin Time"
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement = 2
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement_tiebreaker = "Head to Head"
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement = 3
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement_tiebreaker = ""
    assert Wrestler.find(translate_name_to_id("Test4")).pool_placement = 4
    assert Wrestler.find(translate_name_to_id("Test5")).pool_placement = 5
    assert Wrestler.find(translate_name_to_id("Test6")).pool_placement = 6
  end

   test "Pool order three way tie with quickest pin times but pin time accumulation is tied between two wrestlers" do
    finishedWithTieQuickestPinTwoWayTie
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement = 2
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement_tiebreaker = "Pin Time"
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement = 3
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement_tiebreaker = ""
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement = 1
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement_tiebreaker = "Head to Head"
    assert Wrestler.find(translate_name_to_id("Test4")).pool_placement = 4
    assert Wrestler.find(translate_name_to_id("Test5")).pool_placement = 5
    assert Wrestler.find(translate_name_to_id("Test6")).pool_placement = 6
  end

  test "Pool order three way tie with deducted points" do
    finishedWithDeductedPoints
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement = 1
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement_tiebreaker = "Head to Head"
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement = 2
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement_tiebreaker = "Least Deducted Points"
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement = 1
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement_tiebreaker = ""
    assert Wrestler.find(translate_name_to_id("Test4")).pool_placement = 4
    assert Wrestler.find(translate_name_to_id("Test5")).pool_placement = 5
    assert Wrestler.find(translate_name_to_id("Test6")).pool_placement = 6
  end

  test "Pool order three way tie with deducted points but least deducted is tied between two wrestlers" do
    finishedWithDeductedPointsTwoWayTie
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement = 3
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement_tiebreaker = ""
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement = 2
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement_tiebreaker = "Least Deducted Points"
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement = 1
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement_tiebreaker = "Head to Head"
    assert Wrestler.find(translate_name_to_id("Test4")).pool_placement = 4
    assert Wrestler.find(translate_name_to_id("Test5")).pool_placement = 5
    assert Wrestler.find(translate_name_to_id("Test6")).pool_placement = 6
  end

  test "Pool order three way tie with deducted points but least deducted is tied between two wrestlers with zero" do
    finishedWithDeductedPointsTwoWayTieWithZero
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement = 3
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement_tiebreaker = ""
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement = 2
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement_tiebreaker = "Least Deducted Points"
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement = 1
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement_tiebreaker = "Head to Head"
    assert Wrestler.find(translate_name_to_id("Test4")).pool_placement = 4
    assert Wrestler.find(translate_name_to_id("Test5")).pool_placement = 5
    assert Wrestler.find(translate_name_to_id("Test6")).pool_placement = 6
  end

  test "Pool order three way tie with coin flip" do
  	finishedWithTieCoinFlip
    assert Wrestler.where("weight_id = ? AND pool_placement = 1",@weight.id).first.pool_placement_tiebreaker = "Coin Flip"
    assert Wrestler.where("weight_id = ? AND pool_placement = 2",@weight.id).first.pool_placement_tiebreaker = "Head to Head"
  end
end