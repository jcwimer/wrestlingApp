class CalculateWrestlerTeamScore
    def initialize( wrestler )
      @wrestler = wrestler
      @tournament = @wrestler.tournament
    end

    def totalScore
        if @wrestler.extra or @wrestler.matches.count == 0
			return 0
        else
            earnedPoints - deductedPoints
        end
    end

    def earnedPoints
        return poolPoints + bracketPoints + placement_points + bonusWinPoints + byePoints
    end

    def deductedPoints
        points = 0
		@wrestler.deductedPoints.each do |d|
			points = points + d.points
		end
		points
    end

    def placement_points
        return PoolBracketPlacementPoints.new(@wrestler).calcPoints if @tournament.tournament_type == "Pool to bracket"
        return ModifiedSixteenManPlacementPoints.new(@wrestler).calc_points if @tournament.tournament_type.include? "Modified 16 Man Double Elimination"
        return DoubleEliminationPlacementPoints.new(@wrestler).calc_points if @tournament.tournament_type.include? "Regular Double Elimination"
        return 0
    end

    def bracketPoints
        (@wrestler.championship_advancement_wins.size * 2) + (@wrestler.consolation_advancement_wins.size * 1)
    end

    def poolPoints
        if @tournament.tournament_type == "Pool to bracket"
          (@wrestler.pool_wins.size * 2)
        else
          0
        end
    end

    def byePoints
        points = 0
        if @tournament.tournament_type == "Pool to bracket"
            if @wrestler.pool_wins.size >= 1 and @wrestler.has_a_pool_bye == true
              points += 2
            end
        end
        if @tournament.tournament_type.include? "Regular Double Elimination"
            if @wrestler.championship_advancement_wins.size > 0 or @wrestler.matches_won.select{|m| m.bracket_position == "1/2"}.size > 0
                # if they have a win in the championship round or if they got a bye all the way to finals and won the finals
                points += @wrestler.championship_byes.size * 2
            end
            if @wrestler.consolation_advancement_wins.size > 0 or @wrestler.matches_won.select{|m| m.bracket_position == "3/4"}.size > 0
                # if they have a win in the consolation round or if they got a bye all the way to 3rd/4th match and won
                points += @wrestler.consolation_byes.size * 1
            end
        end
        if @tournament.tournament_type.include? "Modified 16 Man Double Elimination"
            if @wrestler.championship_advancement_wins.size > 0 or @wrestler.matches_won.select{|m| m.bracket_position == "1/2"}.size > 0
                # if they have a win in the championship round or if they got a bye all the way to finals and won the finals
                points += @wrestler.championship_byes.size * 2
            end
            if @wrestler.consolation_advancement_wins.size > 0 or @wrestler.matches_won.select{|m| m.bracket_position == "5/6"}.size > 0
                # if they have a win in the consolation round or if they got a bye all the way to 5th/6th match and won
                # since the consolation bracket goes to 5/6 in a modified tournament
                points += @wrestler.consolation_byes.size * 1
            end
        end
        return points
    end

    def bonusWinPoints
        (@wrestler.pin_wins.size * 2) + (@wrestler.tech_wins.size * 1.5) + (@wrestler.major_wins.size * 1)
    end

end
