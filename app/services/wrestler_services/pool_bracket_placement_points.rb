class PoolBracketPlacementPoints
    def initialize(wrestler)
		@wrestler = wrestler
		@bracket = wrestler.weight.pool_bracket_type
        # reverse is needed below for descending order
        @largest_bracket = wrestler.tournament.weights.sort_by{|w| w.wrestlers.size}.reverse.first.pool_bracket_type
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
           return PlacementPoints.new(number_of_placers).fourthPlace
        end
        if bracket_position_size("Quarter") > 0
            return PlacementPoints.new(number_of_placers).eighthPlace
        end
        return 0
    end
    
    def twoPoolsToSemi
        if bracket_position_size("Semis") > 0
            return PlacementPoints.new(number_of_placers).fourthPlace
        end
        if bracket_position_size("Conso Semis") > 0
            return PlacementPoints.new(number_of_placers).eighthPlace
        end
        return 0
    end
    
    def fourPoolsToSemi
        if bracket_position_size("Semis") > 0
            return PlacementPoints.new(number_of_placers).fourthPlace
        end
        if bracket_position_size("Conso Semis") > 0
            return PlacementPoints.new(number_of_placers).eighthPlace
        end
        return 0
    end
    
    def onePool
           if @wrestler.pool_placement == 1
               return PlacementPoints.new(number_of_placers).firstPlace
           elsif @wrestler.pool_placement == 2
                return PlacementPoints.new(number_of_placers).secondPlace
           elsif @wrestler.pool_placement == 3 
                return PlacementPoints.new(number_of_placers).thirdPlace
           elsif @wrestler.pool_placement == 4 
                return PlacementPoints.new(number_of_placers).fourthPlace
           end
            return 0
    end
    
    def finalMatchPoints
        if  won_bracket_position_size("1/2") > 0
            return PlacementPoints.new(number_of_placers).firstPlace
        end
        if  won_bracket_position_size("3/4") > 0
            return PlacementPoints.new(number_of_placers).thirdPlace
        end
        if  won_bracket_position_size("5/6") > 0
            return PlacementPoints.new(number_of_placers).fifthPlace
        end
        if  won_bracket_position_size("7/8") > 0
            return PlacementPoints.new(number_of_placers).seventhPlace
        end
        if bracket_position_size("1/2") > 0
            return PlacementPoints.new(number_of_placers).secondPlace
        end
        if bracket_position_size("3/4") > 0
            return PlacementPoints.new(number_of_placers).fourthPlace
        end
        if bracket_position_size("5/6") > 0
            return PlacementPoints.new(number_of_placers).sixthPlace
        end
        if bracket_position_size("7/8") > 0
            return PlacementPoints.new(number_of_placers).eighthPlace
        end
        return 0
    end
end
