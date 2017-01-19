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
        return poolPoints + bracketPoints + placementPoints + bonusWinPoints
    end
    
    def deductedPoints
        points = 0
		@wrestler.deductedPoints.each do |d|
			points = points + d.points
		end
		points
    end
    
    def placementPoints
        PoolBracketPlacementPoints.new(@wrestler).calcPoints if @tournament.tournament_type == "Pool to bracket"
    end
    
    def bracketPoints
        (@wrestler.championshipAdvancementWins.size * 2) + (@wrestler.consoAdvancementWins.size * 1)
    end
    
    def poolPoints
        if @tournament.tournament_type == "Pool to bracket"
            if @wrestler.poolWins.size >= 1 and @wrestler.hasAPoolBye == true
                ((@wrestler.poolWins.size * 2) + 2)
            else
                (@wrestler.poolWins.size * 2)
            end
        else
            0
        end
    end
    
    def bonusWinPoints
        (@wrestler.pinWins.size * 2) + (@wrestler.techWins.size * 1.5) + (@wrestler.majorWins.size * 1) 
    end
    
end