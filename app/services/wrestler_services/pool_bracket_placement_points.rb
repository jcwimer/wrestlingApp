class PoolBracketPlacementPoints
    def initialize(wrestler)
		@wrestler = wrestler
		@bracket = wrestler.weight.pool_bracket_type
        @largest_bracket = wrestler.tournament.weights.sort_by{|w| w.wrestlers.size}.first.pool_bracket_type
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

    def number_of_placers
        if @largest_bracket == "twoPoolsToSemi" or @largest_bracket == "twoPoolsToFinal" or @largest_bracket == "onePool"
            return 4
        else
            return 8
        end 
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
           if @wrestler.pool_placement == 1
               return firstPlace
           elsif @wrestler.pool_placement == 2
                return secondPlace
           elsif @wrestler.pool_placement == 3 
                return thirdPlace
           elsif @wrestler.pool_placement == 4 
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
        if number_of_placers == 4
            return 14
        else    
            return 16
        end
    end
    
    def secondPlace
        if number_of_placers == 4
            return 10
        else    
            return 12
        end
    end
    
    def thirdPlace
        if number_of_placers == 4
            return 9
        else    
            return 7
        end
    end
    
    def fourthPlace
        if number_of_placers == 4
            return 4
        else    
            return 7
        end
    end
    
    def fifthPlace
        5  
    end
    
    def sixthPlace
        3  
    end
    
    def seventhPlace
        2  
    end
    
    def eighthPlace
        1 
    end
end
