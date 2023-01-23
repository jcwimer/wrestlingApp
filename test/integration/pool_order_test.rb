require 'test_helper'

class PoolAdvancementTest < ActionDispatch::IntegrationTest

  def setup
    create_pool_tournament_single_weight(6)
  end

  test "Pool order based on wins" do
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
    
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement == 1
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement == 2
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement == 3
    assert Wrestler.find(translate_name_to_id("Test4")).pool_placement == 4
    assert Wrestler.find(translate_name_to_id("Test5")).pool_placement == 5
    assert Wrestler.find(translate_name_to_id("Test6")).pool_placement == 6
  end

  test "Pool order three way tie with most team points" do
  	end_match_with_pin(match_wrestler_vs("Test1","Test2"),"Test1")
    end_match(match_wrestler_vs("Test1","Test4"),"Test1")
    end_match(match_wrestler_vs("Test1","Test5"),"Test1")
    end_match(match_wrestler_vs("Test1","Test6"),"Test1")
    
    end_match(match_wrestler_vs("Test2","Test3"),"Test2")
    end_match(match_wrestler_vs("Test2","Test4"),"Test2")
    end_match(match_wrestler_vs("Test2","Test5"),"Test2")
    end_match(match_wrestler_vs("Test2","Test6"),"Test2")
    
    end_match(match_wrestler_vs("Test1","Test3"),"Test3")
    end_match(match_wrestler_vs("Test3","Test4"),"Test3")
    end_match(match_wrestler_vs("Test3","Test5"),"Test3")
    end_match(match_wrestler_vs("Test3","Test6"),"Test3")
    
    end_match(match_wrestler_vs("Test4","Test5"),"Test4")
    end_match(match_wrestler_vs("Test4","Test6"),"Test4")
    
    end_match(match_wrestler_vs("Test5","Test6"),"Test5")
    
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement == 1
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement_tiebreaker == "Team Points"
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement == 2
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement_tiebreaker == "Head to Head"
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement == 3
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement_tiebreaker == nil
    assert Wrestler.find(translate_name_to_id("Test4")).pool_placement == 4
    assert Wrestler.find(translate_name_to_id("Test5")).pool_placement == 5
    assert Wrestler.find(translate_name_to_id("Test6")).pool_placement == 6
  end

  test "Pool order three way tie with most team points where first place won by wins" do
    end_match(match_wrestler_vs("Test1","Test2"),"Test1")
    end_match(match_wrestler_vs("Test1","Test3"),"Test1")
    end_match(match_wrestler_vs("Test1","Test4"),"Test1")
    end_match(match_wrestler_vs("Test1","Test5"),"Test1")
    end_match(match_wrestler_vs("Test1","Test6"),"Test1")
    
    end_match_with_pin(match_wrestler_vs("Test2","Test3"),"Test2")
    end_match(match_wrestler_vs("Test2","Test5"),"Test2")
    end_match(match_wrestler_vs("Test2","Test6"),"Test2")
    
    end_match(match_wrestler_vs("Test3","Test4"),"Test3")
    end_match(match_wrestler_vs("Test3","Test5"),"Test3")
    end_match(match_wrestler_vs("Test3","Test6"),"Test3")
    
    end_match(match_wrestler_vs("Test2","Test4"),"Test4")
    end_match(match_wrestler_vs("Test4","Test5"),"Test4")
    end_match(match_wrestler_vs("Test4","Test6"),"Test4")
    
    end_match(match_wrestler_vs("Test5","Test6"),"Test5")  
    
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement == 1
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement_tiebreaker == nil
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement == 2
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement_tiebreaker == "Team Points"
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement == 3
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement_tiebreaker == "Head to Head"
    assert Wrestler.find(translate_name_to_id("Test4")).pool_placement == 4
    assert Wrestler.find(translate_name_to_id("Test4")).pool_placement_tiebreaker == nil
    assert Wrestler.find(translate_name_to_id("Test5")).pool_placement == 5
    assert Wrestler.find(translate_name_to_id("Test6")).pool_placement == 6
  end

  test "Pool order three way tie with most team points but most team points are tied between two wrestlers" do
    end_match_with_pin(match_wrestler_vs("Test1","Test2"),"Test1")
    end_match(match_wrestler_vs("Test1","Test4"),"Test1")
    end_match(match_wrestler_vs("Test1","Test5"),"Test1")
    end_match(match_wrestler_vs("Test1","Test6"),"Test1")
    
    end_match(match_wrestler_vs("Test2","Test3"),"Test2")
    end_match(match_wrestler_vs("Test2","Test4"),"Test2")
    end_match(match_wrestler_vs("Test2","Test5"),"Test2")
    end_match(match_wrestler_vs("Test2","Test6"),"Test2")
    
    end_match_with_pin(match_wrestler_vs("Test1","Test3"),"Test3")
    end_match(match_wrestler_vs("Test3","Test4"),"Test3")
    end_match(match_wrestler_vs("Test3","Test5"),"Test3")
    end_match(match_wrestler_vs("Test3","Test6"),"Test3")
    
    end_match(match_wrestler_vs("Test4","Test5"),"Test4")
    end_match(match_wrestler_vs("Test4","Test6"),"Test4")
    
    end_match(match_wrestler_vs("Test5","Test6"),"Test5")
    
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement == 2
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement_tiebreaker == "Team Points"
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement = 3
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement_tiebreaker == nil
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement == 1
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement_tiebreaker == "Head to Head"
    assert Wrestler.find(translate_name_to_id("Test4")).pool_placement == 4
    assert Wrestler.find(translate_name_to_id("Test5")).pool_placement == 5
    assert Wrestler.find(translate_name_to_id("Test6")).pool_placement == 6
  end

  test "Pool order three way tie with most pins" do
  	#Test1 has 12 points
    #Test2 has 12 points
    #Test3 has 12 points

    end_match_with_pin(match_wrestler_vs("Test1","Test2"),"Test1")
    end_match(match_wrestler_vs("Test1","Test4"),"Test1")
    end_match(match_wrestler_vs("Test1","Test5"),"Test1")
    end_match_with_pin(match_wrestler_vs("Test1","Test6"),"Test1")
    
    end_match_with_major(match_wrestler_vs("Test2","Test3"),"Test2")
    end_match_with_major(match_wrestler_vs("Test2","Test4"),"Test2")
    end_match_with_major(match_wrestler_vs("Test2","Test5"),"Test2")
    end_match_with_major(match_wrestler_vs("Test2","Test6"),"Test2")
    
    end_match_with_major(match_wrestler_vs("Test1","Test3"),"Test3")
    end_match_with_major(match_wrestler_vs("Test3","Test4"),"Test3")
    end_match_with_major(match_wrestler_vs("Test3","Test5"),"Test3")
    end_match_with_major(match_wrestler_vs("Test3","Test6"),"Test3")
    
    end_match(match_wrestler_vs("Test4","Test5"),"Test4")
    end_match(match_wrestler_vs("Test4","Test6"),"Test4")
    
    end_match(match_wrestler_vs("Test5","Test6"),"Test5") 
    
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement == 1
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement_tiebreaker == "Most Pins"
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement == 2
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement_tiebreaker == "Head to Head"
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement == 3
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement_tiebreaker == "Team Points"
    assert Wrestler.find(translate_name_to_id("Test4")).pool_placement == 4
    assert Wrestler.find(translate_name_to_id("Test5")).pool_placement == 5
    assert Wrestler.find(translate_name_to_id("Test6")).pool_placement == 6
  end

  test "Pool order three way tie with most tech falls" do
  	#Test1 has 11 points
    #Test2 has 11 points
    #Test3 has 11 points

    end_match_with_tech(match_wrestler_vs("Test1","Test2"),"Test1")
    end_match(match_wrestler_vs("Test1","Test4"),"Test1")
    end_match(match_wrestler_vs("Test1","Test5"),"Test1")
    end_match_with_tech(match_wrestler_vs("Test1","Test6"),"Test1")
    
    end_match(match_wrestler_vs("Test2","Test3"),"Test2")
    end_match_with_major(match_wrestler_vs("Test2","Test4"),"Test2")
    end_match_with_major(match_wrestler_vs("Test2","Test5"),"Test2")
    end_match_with_major(match_wrestler_vs("Test2","Test6"),"Test2")
    
    end_match(match_wrestler_vs("Test1","Test3"),"Test3")
    end_match_with_major(match_wrestler_vs("Test3","Test4"),"Test3")
    end_match_with_major(match_wrestler_vs("Test3","Test5"),"Test3")
    end_match_with_major(match_wrestler_vs("Test3","Test6"),"Test3")
    
    end_match(match_wrestler_vs("Test4","Test5"),"Test4")
    end_match(match_wrestler_vs("Test4","Test6"),"Test4")
    
    end_match(match_wrestler_vs("Test5","Test6"),"Test5")
    
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement == 1
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement_tiebreaker == "Most Techs"
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement == 2
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement_tiebreaker == "Head to Head"
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement == 3
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement_tiebreaker == "Team Points"
    assert Wrestler.find(translate_name_to_id("Test4")).pool_placement == 4
    assert Wrestler.find(translate_name_to_id("Test5")).pool_placement == 5
    assert Wrestler.find(translate_name_to_id("Test6")).pool_placement == 6
  end

  test "Pool order three way tie with quickest pin times" do
    # end_match_with_pin 5:00
    # end_match_with_quick_pin 1:20
    # end_match_with_quickest_pin 0:20
    
  	# Test1 has 9:00 of pin time
    # Test2 has 12:40 of pin time
    # Test3 has 20:00 of pin time

    end_match_with_pin(match_wrestler_vs("Test1","Test2"),"Test1")
    end_match_with_quick_pin(match_wrestler_vs("Test1","Test4"),"Test1")
    end_match_with_quick_pin(match_wrestler_vs("Test1","Test5"),"Test1")
    end_match_with_quick_pin(match_wrestler_vs("Test1","Test6"),"Test1")
    
    end_match_with_pin(match_wrestler_vs("Test2","Test3"),"Test2")
    end_match_with_pin(match_wrestler_vs("Test2","Test4"),"Test2")
    end_match_with_quick_pin(match_wrestler_vs("Test2","Test5"),"Test2")
    end_match_with_quick_pin(match_wrestler_vs("Test2","Test6"),"Test2")
    
    end_match_with_pin(match_wrestler_vs("Test1","Test3"),"Test3")
    end_match_with_pin(match_wrestler_vs("Test3","Test4"),"Test3")
    end_match_with_pin(match_wrestler_vs("Test3","Test5"),"Test3")
    end_match_with_pin(match_wrestler_vs("Test3","Test6"),"Test3")
    
    end_match(match_wrestler_vs("Test4","Test5"),"Test4")
    end_match(match_wrestler_vs("Test4","Test6"),"Test4")
    end_match(match_wrestler_vs("Test5","Test6"),"Test5") 
    
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement == 1
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement_tiebreaker == "Pin Time"
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement == 2
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement_tiebreaker == "Head to Head"
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement == 3
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement_tiebreaker == "Decision Points Scored"
    assert Wrestler.find(translate_name_to_id("Test4")).pool_placement == 4
    assert Wrestler.find(translate_name_to_id("Test5")).pool_placement == 5
    assert Wrestler.find(translate_name_to_id("Test6")).pool_placement == 6
  end

  test "Pool order three way tie with quickest pin times but pin time accumulation is tied between two wrestlers" do
    # end_match_with_pin 5:00
    # end_match_with_quick_pin 1:20
    # end_match_with_quickest_pin 0:20
    
  	# Test1 has 9:00 of pin time
    # Test2 has 9:00 of pin time
    # Test3 has 12:40 of pin time

    end_match_with_pin(match_wrestler_vs("Test1","Test2"),"Test1")
    end_match_with_quick_pin(match_wrestler_vs("Test1","Test4"),"Test1")
    end_match_with_quick_pin(match_wrestler_vs("Test1","Test5"),"Test1")
    end_match_with_quick_pin(match_wrestler_vs("Test1","Test6"),"Test1")
    
    end_match_with_pin(match_wrestler_vs("Test2","Test3"),"Test2")
    end_match_with_quick_pin(match_wrestler_vs("Test2","Test4"),"Test2")
    end_match_with_quick_pin(match_wrestler_vs("Test2","Test5"),"Test2")
    end_match_with_quick_pin(match_wrestler_vs("Test2","Test6"),"Test2")
    
    end_match_with_pin(match_wrestler_vs("Test1","Test3"),"Test3")
    end_match_with_pin(match_wrestler_vs("Test3","Test4"),"Test3")
    end_match_with_quick_pin(match_wrestler_vs("Test3","Test5"),"Test3")
    end_match_with_quick_pin(match_wrestler_vs("Test3","Test6"),"Test3")
    
    end_match(match_wrestler_vs("Test4","Test5"),"Test4")
    end_match(match_wrestler_vs("Test4","Test6"),"Test4")
    
    end_match(match_wrestler_vs("Test5","Test6"),"Test5") 
    
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement == 1
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement_tiebreaker == "Head to Head"
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement == 2
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement_tiebreaker == "Pin Time"
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement == 3
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement_tiebreaker == "Decision Points Scored"
    assert Wrestler.find(translate_name_to_id("Test4")).pool_placement == 4
    assert Wrestler.find(translate_name_to_id("Test5")).pool_placement == 5
    assert Wrestler.find(translate_name_to_id("Test6")).pool_placement == 6
  end

  test "Pool order three way tie with deducted points" do
    team_point_adjusts_for_wrestler("Test2", 1)
    team_point_adjusts_for_wrestler("Test3", 2)

    end_match(match_wrestler_vs("Test1","Test2"),"Test1")
    end_match(match_wrestler_vs("Test1","Test4"),"Test1")
    end_match(match_wrestler_vs("Test1","Test5"),"Test1")
    end_match(match_wrestler_vs("Test1","Test6"),"Test1")
    
    end_match(match_wrestler_vs("Test2","Test3"),"Test2")
    end_match(match_wrestler_vs("Test2","Test4"),"Test2")
    end_match(match_wrestler_vs("Test2","Test5"),"Test2")
    end_match(match_wrestler_vs("Test2","Test6"),"Test2")
    
    end_match(match_wrestler_vs("Test1","Test3"),"Test3")
    end_match(match_wrestler_vs("Test3","Test4"),"Test3")
    end_match(match_wrestler_vs("Test3","Test5"),"Test3")
    end_match(match_wrestler_vs("Test3","Test6"),"Test3")
    
    end_match(match_wrestler_vs("Test4","Test5"),"Test4")
    end_match(match_wrestler_vs("Test4","Test6"),"Test4")
    end_match(match_wrestler_vs("Test5","Test6"),"Test5") 
    
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement == 1
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement_tiebreaker == "Least Deducted Points"
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement == 2
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement_tiebreaker == "Least Deducted Points"
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement == 3
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement_tiebreaker == nil
    assert Wrestler.find(translate_name_to_id("Test4")).pool_placement == 4
    assert Wrestler.find(translate_name_to_id("Test5")).pool_placement == 5
    assert Wrestler.find(translate_name_to_id("Test6")).pool_placement == 6
  end

  test "Pool order three way tie with deducted points but least deducted is tied between two wrestlers" do
    team_point_adjusts_for_wrestler("Test1", 2)
    team_point_adjusts_for_wrestler("Test2", 1)
    team_point_adjusts_for_wrestler("Test3", 1)

    end_match(match_wrestler_vs("Test1","Test2"),"Test1")
    end_match(match_wrestler_vs("Test1","Test4"),"Test1")
    end_match(match_wrestler_vs("Test1","Test5"),"Test1")
    end_match(match_wrestler_vs("Test1","Test6"),"Test1")
    
    end_match(match_wrestler_vs("Test2","Test3"),"Test2")
    end_match(match_wrestler_vs("Test2","Test4"),"Test2")
    end_match(match_wrestler_vs("Test2","Test5"),"Test2")
    end_match(match_wrestler_vs("Test2","Test6"),"Test2")
    
    end_match(match_wrestler_vs("Test1","Test3"),"Test3")
    end_match(match_wrestler_vs("Test3","Test4"),"Test3")
    end_match(match_wrestler_vs("Test3","Test5"),"Test3")
    end_match(match_wrestler_vs("Test3","Test6"),"Test3")
    
    end_match(match_wrestler_vs("Test4","Test5"),"Test4")
    end_match(match_wrestler_vs("Test4","Test6"),"Test4")
    
    end_match(match_wrestler_vs("Test5","Test6"),"Test5")
    
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement == 3
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement_tiebreaker == nil
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement == 1
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement_tiebreaker == "Head to Head"
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement == 2
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement_tiebreaker == "Least Deducted Points"
    assert Wrestler.find(translate_name_to_id("Test4")).pool_placement == 4
    assert Wrestler.find(translate_name_to_id("Test5")).pool_placement == 5
    assert Wrestler.find(translate_name_to_id("Test6")).pool_placement == 6
  end

  test "Pool order three way tie with deducted points but least deducted is tied between two wrestlers with zero" do
    team_point_adjusts_for_wrestler("Test1", 1)

    end_match(match_wrestler_vs("Test1","Test2"),"Test1")
    end_match(match_wrestler_vs("Test1","Test4"),"Test1")
    end_match(match_wrestler_vs("Test1","Test5"),"Test1")
    end_match(match_wrestler_vs("Test1","Test6"),"Test1")
    
    end_match(match_wrestler_vs("Test2","Test3"),"Test2")
    end_match(match_wrestler_vs("Test2","Test4"),"Test2")
    end_match(match_wrestler_vs("Test2","Test5"),"Test2")
    end_match(match_wrestler_vs("Test2","Test6"),"Test2")
    
    end_match(match_wrestler_vs("Test1","Test3"),"Test3")
    end_match(match_wrestler_vs("Test3","Test4"),"Test3")
    end_match(match_wrestler_vs("Test3","Test5"),"Test3")
    end_match(match_wrestler_vs("Test3","Test6"),"Test3")
    
    end_match(match_wrestler_vs("Test4","Test5"),"Test4")
    end_match(match_wrestler_vs("Test4","Test6"),"Test4")
    
    end_match(match_wrestler_vs("Test5","Test6"),"Test5")
    
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement == 3
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement_tiebreaker == nil
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement == 1
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement_tiebreaker == "Head to Head"
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement == 2
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement_tiebreaker == "Least Deducted Points"
    assert Wrestler.find(translate_name_to_id("Test4")).pool_placement == 4
    assert Wrestler.find(translate_name_to_id("Test5")).pool_placement == 5
    assert Wrestler.find(translate_name_to_id("Test6")).pool_placement == 6
  end

  test "Pool order three way tie with coin flip" do
  	end_match(match_wrestler_vs("Test1","Test2"),"Test1")
    end_match(match_wrestler_vs("Test1","Test4"),"Test1")
    end_match(match_wrestler_vs("Test1","Test5"),"Test1")
    end_match(match_wrestler_vs("Test1","Test6"),"Test1")
    
    end_match(match_wrestler_vs("Test2","Test3"),"Test2")
    end_match(match_wrestler_vs("Test2","Test4"),"Test2")
    end_match(match_wrestler_vs("Test2","Test5"),"Test2")
    end_match(match_wrestler_vs("Test2","Test6"),"Test2")
    
    end_match(match_wrestler_vs("Test1","Test3"),"Test3")
    end_match(match_wrestler_vs("Test3","Test4"),"Test3")
    end_match(match_wrestler_vs("Test3","Test5"),"Test3")
    end_match(match_wrestler_vs("Test3","Test6"),"Test3")
    
    end_match(match_wrestler_vs("Test4","Test5"),"Test4")
    end_match(match_wrestler_vs("Test4","Test6"),"Test4")
    
    end_match(match_wrestler_vs("Test5","Test6"),"Test5")
    
    assert Wrestler.where("weight_id = ? AND pool_placement = 1",@weight.id).first.pool_placement_tiebreaker == "Coin Flip"
    assert Wrestler.where("weight_id = ? AND pool_placement = 2",@weight.id).first.pool_placement_tiebreaker == "Head to Head"
  end
  
  test "Pool order when two two way ties head to head tiebreakers" do
    end_match(match_wrestler_vs("Test1","Test2"),"Test1")
    end_match(match_wrestler_vs("Test1","Test3"),"Test1")
    end_match(match_wrestler_vs("Test1","Test5"),"Test1")
    end_match(match_wrestler_vs("Test1","Test6"),"Test1")
    
    end_match(match_wrestler_vs("Test2","Test3"),"Test2")
    end_match(match_wrestler_vs("Test2","Test4"),"Test2")
    end_match(match_wrestler_vs("Test2","Test5"),"Test2")
    end_match(match_wrestler_vs("Test2","Test6"),"Test2")
    
    end_match(match_wrestler_vs("Test3","Test4"),"Test3")
    end_match(match_wrestler_vs("Test3","Test5"),"Test3")
    end_match(match_wrestler_vs("Test3","Test6"),"Test3")
    
    end_match(match_wrestler_vs("Test1","Test4"),"Test4")
    end_match(match_wrestler_vs("Test4","Test5"),"Test4")
    end_match(match_wrestler_vs("Test4","Test6"),"Test4")
    
    end_match(match_wrestler_vs("Test5","Test6"),"Test5")
    
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement == 1
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement_tiebreaker == "Head to Head"
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement == 2
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement == 3
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement_tiebreaker == "Head to Head"
    assert Wrestler.find(translate_name_to_id("Test4")).pool_placement == 4
  end
  
  test "Pool order with 4 wrestlers and two two way ties" do
    # Setup
    Wrestler.find(translate_name_to_id("Test5")).destroy
    Wrestler.find(translate_name_to_id("Test6")).destroy
    GenerateTournamentMatches.new(Wrestler.find(translate_name_to_id("Test1")).tournament).generate
    weight = Wrestler.find(translate_name_to_id("Test1")).weight
    
    # Match results
    # Test1 is the best wrestler but got injured after round 1 and forfeited out
    end_match_custom(match_wrestler_vs("Test3","Test4"),"Tech Fall","0-16","Test3")
    end_match_custom(match_wrestler_vs("Test2","Test3"),"Pin","0:35","Test3")
    
    end_match_custom(match_wrestler_vs("Test2","Test4"),"Pin","1:13","Test4")
    end_match_custom(match_wrestler_vs("Test4","Test1"),"Forfeit","","Test4")
    
    end_match_custom(match_wrestler_vs("Test2","Test1"),"Forfeit","","Test2")
    
    end_match_custom(match_wrestler_vs("Test1","Test3"),"Pin","0:44","Test1")
    

    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement == 1
    assert Wrestler.find(translate_name_to_id("Test3")).pool_placement_tiebreaker == "Head to Head"
    assert Wrestler.find(translate_name_to_id("Test4")).pool_placement == 2
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement == 3
    assert Wrestler.find(translate_name_to_id("Test2")).pool_placement_tiebreaker == "Head to Head"
    assert Wrestler.find(translate_name_to_id("Test1")).pool_placement == 4
  end
end