class CalculateWrestlerTeamScore
    def initialize( wrestler )
      @wrestler = wrestler
      @tournament = @wrestler.tournament
    end

    def totalScore
        if @wrestler.extra or @wrestler.all_matches.count == 0
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

    def pool_bonus_points
        if @tournament.tournament_type == "Pool to bracket"
            (@wrestler.pin_wins.select{|m| m.bracket_position == "Pool"}.size * 2) + (@wrestler.tech_wins.select{|m| m.bracket_position == "Pool"}.size * 1.5) + (@wrestler.major_wins.select{|m| m.bracket_position == "Pool"}.size * 1)
        else
            0
        end
    end

    def byePoints
        points = 0
        if @tournament.tournament_type == "Pool to bracket"
            if pool_bye_points_eligible?
              points += 2
            end
        end
        if @tournament.tournament_type.include? "Double Elimination"
            if @wrestler.championship_advancement_wins.any? &&
               @wrestler.championship_byes.any? &&
               any_bye_round_had_wrestled_match?(@wrestler.championship_byes)
                points += 2
            end
            if @wrestler.consolation_advancement_wins.any? &&
               @wrestler.consolation_byes.any? &&
               any_bye_round_had_wrestled_match?(@wrestler.consolation_byes)
                points += 1
            end
        end
        return points
    end

    def bonusWinPoints
        (@wrestler.pin_wins.size * 2) + (@wrestler.tech_wins.size * 1.5) + (@wrestler.major_wins.size * 1)
    end

    private

    def pool_bye_points_eligible?
        return false unless @wrestler.pool_wins.size >= 1
        return false unless @wrestler.weight.pools.to_i > 1

        wrestler_pool_size = @wrestler.weight.wrestlers_in_pool(@wrestler.pool).size
        largest_pool_size = (1..@wrestler.weight.pools).map { |pool_number| @wrestler.weight.wrestlers_in_pool(pool_number).size }.max

        wrestler_pool_size < largest_pool_size
    end

    def any_bye_round_had_wrestled_match?(bye_matches)
        bye_matches.any? do |bye_match|
            next false if bye_match.round.nil?

            @wrestler.weight.matches.any? do |match|
                next false if match.id == bye_match.id
                next false if match.round != bye_match.round
                next false if match.is_consolation_match != bye_match.is_consolation_match

                match.finished == 1 && match.win_type.present? && match.win_type != "BYE"
            end
        end
    end

end
