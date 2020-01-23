class ModifiedSixteenManPlacementPoints
    def initialize(wrestler)
		@wrestler = wrestler
		@number_of_placers = 6
    end

    def calc_points
    	if  won_bracket_position_size("1/2") > 0
            return PlacementPoints.new(@number_of_placers).firstPlace
        elsif bracket_position_size("1/2") > 0
            return PlacementPoints.new(@number_of_placers).secondPlace
        elsif won_bracket_position_size("3/4") > 0
            return PlacementPoints.new(@number_of_placers).thirdPlace
        elsif bracket_position_size("Semis") > 0
            return PlacementPoints.new(@number_of_placers).fourthPlace
        elsif won_bracket_position_size("5/6") > 0
            return PlacementPoints.new(@number_of_placers).fifthPlace
        elsif bracket_position_size("5/6") > 0
        	return PlacementPoints.new(@number_of_placers).sixthPlace
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