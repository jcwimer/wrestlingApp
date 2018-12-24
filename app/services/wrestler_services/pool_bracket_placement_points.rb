class PoolBracketPlacementPoints
    def initialize(wrestler)
		@wrestler = wrestler
		@bracket = wrestler.weight.pool_bracket_type
    end
    
    def calcPoints
        @points = 0 
        whilePointsAreZero { @points = finalMatchPoints }
        if @bracket == "twoPoolsToSemi"
           whilePointsAreZero { @points = twoPoolsToSemi }
        end
        if (@bracket == "fourPoolsToQuarter") or (@bracket == "eightPoolsToQuarter")
           whilePointsAreZero { @points = fourPoolsToQuarter }
        end
        if @bracket == "fourPoolsToSemi"
           whilePointsAreZero { @points = fourPoolsToSemi }
        end
        if @wrestler.weight.wrestlers.size <= 6 && @wrestler.weight.all_pool_matches_finished(1)
            whilePointsAreZero { @points = onePool }
        end
        return @points
    end
    
    def whilePointsAreZero
		if @points == 0
			yield	
		end
    end
    
    def bracket_position_size(bracket_position_name)
        @wrestler.all_matches.select{|m| m.bracket_position == bracket_position_name}.size
    end
    
    def won_bracket_position_size(bracket_position_name)
        @wrestler.matches_won.select{|m| m.bracket_position == bracket_position_name}.size
    end
    
    def fourPoolsToQuarter
        if bracket_position_size("Semis") > 0
           return fourthPlace
        end
        if bracket_position_size("Quarter") > 0
            return eighthPlace
        end
        return 0
    end
    
    def twoPoolsToSemi
        if bracket_position_size("Semis") > 0
            return fourthPlace
        end
        if bracket_position_size("Conso Semis") > 0
            return eighthPlace
        end
        return 0
    end
    
    def fourPoolsToSemi
        if bracket_position_size("Semis") > 0
            return fourthPlace
        end
        if bracket_position_size("Conso Semis") > 0
            return eighthPlace
        end
        return 0
    end
    
    def onePool
           pool_placement_order = @wrestler.weight.pool_placement_order(1)
           if @wrestler == pool_placement_order.first
               return firstPlace
           elsif @wrestler == pool_placement_order.second 
                return secondPlace
           elsif @wrestler == pool_placement_order.third 
                return thirdPlace
           elsif @wrestler == pool_placement_order.fourth 
                return fourthPlace
           end
            return 0
    end
    
    def finalMatchPoints
        if  won_bracket_position_size("1/2") > 0
            return firstPlace
        end
        if  won_bracket_position_size("3/4") > 0
            return thirdPlace
        end
        if  won_bracket_position_size("5/6") > 0
            return fifthPlace
        end
        if  won_bracket_position_size("7/8") > 0
            return seventhPlace
        end
        if bracket_position_size("1/2") > 0
            return secondPlace
        end
        if bracket_position_size("3/4") > 0
            return fourthPlace
        end
        if bracket_position_size("5/6") > 0
            return sixthPlace
        end
        if bracket_position_size("7/8") > 0
            return eighthPlace
        end
        return 0
    end
    
    def firstPlace
       16
    end
    
    def secondPlace
        12
    end
    
    def thirdPlace
        10  
    end
    
    def fourthPlace
        9  
    end
    
    def fifthPlace
        7  
    end
    
    def sixthPlace
        6  
    end
    
    def seventhPlace
        4  
    end
    
    def eighthPlace
        3 
    end
end
