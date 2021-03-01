class DoubleEliminationPlacementPoints
    def initialize(wrestler)
		@wrestler = wrestler
		@number_of_placers = @wrestler.tournament.number_of_placers
    end

    def calc_points
    	if  won_bracket_position_size("1/2") > 0
            return PlacementPoints.new(@number_of_placers).firstPlace
        elsif bracket_position_size("1/2") > 0
            return PlacementPoints.new(@number_of_placers).secondPlace
        elsif won_bracket_position_size("3/4") > 0
            return PlacementPoints.new(@number_of_placers).thirdPlace
        elsif bracket_position_size("3/4") > 0
            return PlacementPoints.new(@number_of_placers).fourthPlace
        elsif won_bracket_position_size("5/6") > 0
            return PlacementPoints.new(@number_of_placers).fifthPlace
        elsif (bracket_position_size("Semis") > 0 or bracket_position_size("Conso Semis") > 0) and @number_of_placers >= 6
            return PlacementPoints.new(@number_of_placers).sixthPlace 
        elsif won_bracket_position_size("7/8") > 0
            return PlacementPoints.new(@number_of_placers).seventhPlace
        elsif bracket_position_size("Conso Quarter") > 0 and @number_of_placers >= 8
            return PlacementPoints.new(@number_of_placers).eighthPlace 
        else
        	return 0
        end
    end

    def bracket_position_size(bracket_position_name)
        @wrestler.all_matches.select{|m| m.bracket_position == bracket_position_name}.size
    end
    
    def won_bracket_position_size(bracket_position_name)
        @wrestler.matches_won.select{|m| m.bracket_position == bracket_position_name}.size
    end
end