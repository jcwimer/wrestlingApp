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
        PoolBracketPlacementPoints.new(@wrestler).calcPoints if @tournament.tournament_type == "Pool to bracket"
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
        if @tournament.tournament_type == "Pool to bracket"
            if @wrestler.pool_wins.size >= 1 and @wrestler.has_a_pool_bye == true
              2
            else
              0
            end
        else
          0
        end
    end

    def bonusWinPoints
        (@wrestler.pin_wins.size * 2) + (@wrestler.tech_wins.size * 1.5) + (@wrestler.major_wins.size * 1)
    end

end
