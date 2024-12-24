require 'test_helper'

class FixMatchWinner < ActionDispatch::IntegrationTest
    def setup
    end

    def winner_by_name(winner_name,match)
        wrestler = @tournament.weights.first.wrestlers.select{|w| w.name == winner_name}.first
        match.winner_id = wrestler.id
        match.finished = 1
        match.win_type = "Decision"
        match.score = "1-0"
        match.save
    end
    
    test "Double elimination advance wrestler should run if the winner changes" do
        create_double_elim_tournament_single_weight(4, "Regular Double Elimination 1-8")
        
        round1 = @tournament.reload.matches.select{|m| m.round == 1}
        winner_by_name("Test1", round1.select{|m| m.bracket_position_number == 1}.first)
        winner_by_name("Test2", round1.select{|m| m.bracket_position_number == 2}.first)

        round1 = @tournament.reload.matches.select{|m| m.round == 1}
        winner_by_name("Test4", round1.select{|m| m.bracket_position_number == 1}.first)

        first_finals = @tournament.reload.matches.select{|m| m.bracket_position == "1/2"}.first
        third_finals = @tournament.reload.matches.select{|m| m.bracket_position == "3/4"}.first
        
        assert first_finals.wrestler1.name == "Test4"
        assert first_finals.wrestler2.name == "Test2"

        assert third_finals.wrestler1.name == "Test1"
        assert third_finals.wrestler2.name == "Test3"
    end

    test "Pool to bracket pool order should run if the winner changes" do
        create_pool_tournament_single_weight(6)

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

        end_match(match_wrestler_vs("Test1","Test2"),"Test2")
        assert Wrestler.find(translate_name_to_id("Test2")).pool_placement == 1
        assert Wrestler.find(translate_name_to_id("Test1")).pool_placement == 2
        assert Wrestler.find(translate_name_to_id("Test3")).pool_placement == 3
        assert Wrestler.find(translate_name_to_id("Test4")).pool_placement == 4
        assert Wrestler.find(translate_name_to_id("Test5")).pool_placement == 5
        assert Wrestler.find(translate_name_to_id("Test6")).pool_placement == 6
    end
end