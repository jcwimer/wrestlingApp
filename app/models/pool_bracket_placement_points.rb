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
        if @bracket == "fourPoolsToQuarter"
           whilePointsAreZero { @points = fourPoolsToQuarter }
        end
        if @bracket == "fourPoolsToSemi"
           whilePointsAreZero { @points = fourPoolsToSemi }
        end
        if wrestler.weight.size <= 6 && wrestler.weight.allPoolMatchesFinished(1)
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
        @wrestler.allMatches.select{|m| m.bracket_position == bracket_position_name}.size
    end
    
    def won_bracket_position_size(bracket_position_name)
        @wrestler.matchesWon.select{|m| m.bracket_position == bracket_position_name}.size
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
       poolOrder = wrestler.weight.poolOrder(1)
       if wrestler == poolOrder.first
           firstPlace
       elsif wrestler == poolOrder.second 
            secondPlace
       elsif wrestler == poolOrder.third 
            thirdPlace
       elsif wrestler == poolOrder.fourth 
            fourthPlace
       end
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
