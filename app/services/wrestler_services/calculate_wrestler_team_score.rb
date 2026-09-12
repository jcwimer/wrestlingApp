# frozen_string_literal: true

module WrestlerServices
  class CalculateWrestlerTeamScore
    def initialize(wrestler)
      @wrestler = wrestler
      @tournament = @wrestler.weight.tournament
    end

    def total_score
      if @wrestler.extra || @wrestler.all_matches.none?
        0
      else
        earned_points - deducted_points
      end
    end

    def earned_points
      pool_points + bracket_points + placement_points + bonus_win_points + bye_points
    end

    def deducted_points
      points = 0
      @wrestler.deductedPoints.each do |d|
        points += d.points
      end
      points
    end

    def placement_points
      return WrestlerServices::PoolBracketPlacementPoints.new(@wrestler).calc_points if @tournament.tournament_type == 'Pool to bracket'
      if @tournament.tournament_type.include? 'Modified 16 Man Double Elimination'
        return WrestlerServices::ModifiedSixteenManPlacementPoints.new(@wrestler).calc_points
      end
      return WrestlerServices::DoubleEliminationPlacementPoints.new(@wrestler).calc_points if @tournament.tournament_type.include? 'Regular Double Elimination'

      0
    end

    def bracket_points
      (@wrestler.championship_advancement_wins.size * 2) + (@wrestler.consolation_advancement_wins.size * 1)
    end

    def pool_points
      if @tournament.tournament_type == 'Pool to bracket'
        (@wrestler.pool_wins.size * 2)
      else
        0
      end
    end

    def pool_bonus_points
      return 0 unless @tournament.tournament_type == 'Pool to bracket'

      pool_pin_wins = @wrestler.pin_wins.count { |match| match.bracket_position == 'Pool' }
      pool_tech_wins = @wrestler.tech_wins.count { |match| match.bracket_position == 'Pool' }
      pool_major_wins = @wrestler.major_wins.count { |match| match.bracket_position == 'Pool' }

      (pool_pin_wins * 2) + (pool_tech_wins * 1.5) + pool_major_wins
    end

    def bye_points
      points = 0
      points += 2 if (@tournament.tournament_type == 'Pool to bracket') && pool_bye_points_eligible?
      if @tournament.tournament_type.include? 'Double Elimination'
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
      points
    end
    alias byePoints bye_points # rubocop:disable Naming/MethodName

    def bonus_win_points
      (@wrestler.pin_wins.size * 2) + (@wrestler.tech_wins.size * 1.5) + (@wrestler.major_wins.size * 1)
    end

    private

    def pool_bye_points_eligible?
      return false unless @wrestler.pool_wins.size >= 1
      return false unless @wrestler.weight.pools.to_i > 1

      wrestler_pool_size = @wrestler.weight.wrestlers_in_pool(@wrestler.pool).size
      largest_pool_size = (1..@wrestler.weight.pools).map do |pool_number|
        @wrestler.weight.wrestlers_in_pool(pool_number).size
      end.max

      wrestler_pool_size < largest_pool_size
    end

    def any_bye_round_had_wrestled_match?(bye_matches)
      bye_matches.any? do |bye_match|
        next false if bye_match.round.nil?

        @wrestler.weight.matches.any? do |match|
          next false if match.id == bye_match.id
          next false if match.round != bye_match.round
          next false if match.consolation_match? != bye_match.consolation_match?

          match.finished == 1 && match.win_type.present? && match.win_type != 'BYE'
        end
      end
    end
  end
end
