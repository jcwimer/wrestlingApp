# frozen_string_literal: true

module BracketAdvancement
  class PoolOrder
    def initialize(wrestlers)
      @wrestlers = wrestlers
    end

    def pool_order
      set_original_points
      while ties?(@wrestlers)
        wrestlers_order_by_pool_advance_points.each do |wrestler|
          wrestlers_with_same_points = wrestlers_order_by_pool_advance_points.select do |w|
            w.pool_advance_points == wrestler.pool_advance_points
          end
          break_tie(wrestlers_with_same_points) if wrestlers_with_same_points.size > 1
        end
      end
      wrestlers_order_by_pool_advance_points.each_with_index do |wrestler, index|
        placement = index + 1
        wrestler.pool_placement = placement
      end
      @wrestlers.sort_by(&:pool_advance_points).reverse!
    end

    def wrestlers_order_by_pool_advance_points
      @wrestlers.sort_by(&:pool_advance_points).reverse
    end

    def set_original_points
      @wrestlers.each do |w|
        w.pool_placement_tiebreaker = nil
        w.pool_placement = nil
        w.pool_advance_points = w.pool_wins.size
      end
    end

    def ties?(wrestlers_to_check)
      wrestlers_with_same_points(wrestlers_to_check).size > 1
    end

    def wrestlers_with_same_points(wrestlers_to_check)
      wrestlers_to_check.each do |w|
        wrestlers_with_same_points_local = wrestlers_to_check.select do |wr|
          wr.pool_advance_points == w.pool_advance_points
        end
        return wrestlers_with_same_points_local if wrestlers_with_same_points_local.size > 1
      end
      []
    end

    def same_tie_size_as_original?(original_tie_size, wrestlers_to_check)
      wrestlers_with_same_points(wrestlers_to_check).size == original_tie_size
    end

    def break_tie(wrestlers_with_same_points)
      original_tie_size = wrestlers_with_same_points.size
      deducted_points(original_tie_size, wrestlers_with_same_points) if same_tie_size_as_original?(
        original_tie_size, wrestlers_with_same_points
      )
      if (original_tie_size == 2) && same_tie_size_as_original?(original_tie_size,
                                                                wrestlers_with_same_points)
        head_to_head(wrestlers_with_same_points)
      end
      team_points(wrestlers_with_same_points) if same_tie_size_as_original?(original_tie_size,
                                                                            wrestlers_with_same_points)
      most_falls(wrestlers_with_same_points) if same_tie_size_as_original?(original_tie_size,
                                                                           wrestlers_with_same_points)
      most_techs(wrestlers_with_same_points) if same_tie_size_as_original?(original_tie_size,
                                                                           wrestlers_with_same_points)
      most_majors(wrestlers_with_same_points) if same_tie_size_as_original?(original_tie_size,
                                                                            wrestlers_with_same_points)
      most_decision_points_scored(wrestlers_with_same_points) if same_tie_size_as_original?(original_tie_size,
                                                                                            wrestlers_with_same_points)
      fastest_pins(wrestlers_with_same_points) if same_tie_size_as_original?(original_tie_size,
                                                                             wrestlers_with_same_points)
      coin_flip(wrestlers_with_same_points) if same_tie_size_as_original?(original_tie_size,
                                                                          wrestlers_with_same_points)
    end

    def head_to_head(wrestlers_with_same_points)
      wrestlers_with_same_points.each do |wr|
        other_wrestler = wrestlers_with_same_points.reject { |w| w.id == wr.id }.first
        next unless other_wrestler

        matches = wr.match_against(other_wrestler).select { |match| match.bracket_position == 'Pool' }
        next unless matches.any? && matches.first.winner == wr

        add_points_to_wrestlers_ahead(wr)
        wr.pool_placement_tiebreaker = 'Head to Head'
        add_points(wr)
      end
    end

    def add_points(wrestler)
      # add_points_to_wrestlers_ahead(wrestler)
      # Cannot go here because if team points are the same the first with points added will stay ahead
      wrestler.pool_advance_points = wrestler.pool_advance_points + 1
    end

    def add_points_to_wrestlers_ahead(wrestler)
      wrestlers_ahead = @wrestlers.select { |w| w.pool_advance_points > wrestler.pool_advance_points }
      wrestlers_ahead.each do |wr|
        wr.pool_advance_points = wr.pool_advance_points + 1
      end
    end

    def deducted_points(original_tie_size, wrestlers_with_same_points)
      points_array = wrestlers_with_same_points.map(&:total_points_deducted)
      least_points = points_array.min
      wrestlers_with_least_deducted_points = wrestlers_with_same_points.select do |w|
        w.total_points_deducted == least_points
      end
      add_points_to_wrestlers_ahead(wrestlers_with_least_deducted_points.first)
      return unless wrestlers_with_least_deducted_points.size != original_tie_size

      wrestlers_with_least_deducted_points.each do |wr|
        wr.pool_placement_tiebreaker = 'Least Deducted Points'
        add_points(wr)
      end
    end

    def most_decision_points_scored(wrestlers_with_same_points)
      points_array = wrestlers_with_same_points.map(&:decision_points_scored_pool)
      most_points = points_array.max
      wrestlers_with_most_points = wrestlers_with_same_points.select do |w|
        w.decision_points_scored_pool == most_points
      end
      add_points_to_wrestlers_ahead(wrestlers_with_most_points.first)
      wrestlers_with_most_points.each do |wr|
        wr.pool_placement_tiebreaker = 'Decision Points Scored'
        add_points(wr)
      end
      second_points = points_array.sort[-2]
      wrestlers_with_second_most_points = wrestlers_with_same_points.select do |w|
        w.decision_points_scored_pool == second_points
      end
      add_points_to_wrestlers_ahead(wrestlers_with_second_most_points.first)
      wrestlers_with_second_most_points.each do |wr|
        wr.pool_placement_tiebreaker = 'Decision Points Scored'
        add_points(wr)
      end
    end

    def fastest_pins(wrestlers_with_same_points)
      wrestlers_with_same_points_with_pins = []
      wrestlers_with_same_points.each do |wr|
        wrestlers_with_same_points_with_pins << wr if wr.pin_wins.any? { |m| m.bracket_position == 'Pool' }
      end
      return unless wrestlers_with_same_points_with_pins.size.positive?

      fastest = wrestlers_with_same_points_with_pins.min_by(&:pin_time_pool).pin_time_pool
      wrestlers_with_fastest_pin = wrestlers_with_same_points_with_pins.select { |w| w.pin_time_pool == fastest }
      add_points_to_wrestlers_ahead(wrestlers_with_fastest_pin.first)
      wrestlers_with_fastest_pin.each do |wr|
        wr.pool_placement_tiebreaker = 'Pin Time'
        add_points(wr)
      end
    end

    def team_points(wrestlers_with_same_points)
      team_points_array = wrestlers_with_same_points.map(&:total_pool_points_for_pool_order)
      most_points = team_points_array.max
      wrestlers_sorted_by_team_points = wrestlers_with_same_points.select do |w|
        w.total_pool_points_for_pool_order == most_points
      end
      add_points_to_wrestlers_ahead(wrestlers_sorted_by_team_points.first)
      wrestlers_sorted_by_team_points.each do |wr|
        wr.pool_placement_tiebreaker = 'Team Points'
        add_points(wr)
      end
    end

    def most_falls(wrestlers_with_same_points)
      most_pins = wrestlers_with_same_points.map do |w|
        w.pin_wins.count { |m| m.bracket_position == 'Pool' }
      end
      pins_max = most_pins.max
      wrestlers_sorted_by_fall_wins = wrestlers_with_same_points.select do |w|
        w.pin_wins.count do |m|
          m.bracket_position == 'Pool'
        end == pins_max
      end
      return unless pins_max.positive?

      add_points_to_wrestlers_ahead(wrestlers_sorted_by_fall_wins.first)
      wrestlers_sorted_by_fall_wins.each do |wr|
        wr.pool_placement_tiebreaker = 'Most Pins'
        add_points(wr)
      end
    end

    def most_techs(wrestlers_with_same_points)
      techs_array = wrestlers_with_same_points.map do |w|
        w.tech_wins.count { |m| m.bracket_position == 'Pool' }
      end
      most_techs_wins = techs_array.max
      wrestlers_sorted_by_tech_wins = wrestlers_with_same_points.select do |w|
        w.tech_wins.count do |m|
          m.bracket_position == 'Pool'
        end == most_techs_wins
      end
      return unless most_techs_wins.positive?

      add_points_to_wrestlers_ahead(wrestlers_sorted_by_tech_wins.first)
      wrestlers_sorted_by_tech_wins.each do |wr|
        wr.pool_placement_tiebreaker = 'Most Techs'
        add_points(wr)
      end
    end

    def most_majors(wrestlers_with_same_points)
      majors_array = wrestlers_with_same_points.map do |w|
        w.major_wins.count { |m| m.bracket_position == 'Pool' }
      end
      most_major_wins = majors_array.max
      wrestlers_sorted_by_major_wins = wrestlers_with_same_points.select do |w|
        w.major_wins.count do |m|
          m.bracket_position == 'Pool'
        end == most_major_wins
      end
      return unless most_major_wins.positive?

      add_points_to_wrestlers_ahead(wrestlers_sorted_by_major_wins.first)
      wrestlers_sorted_by_major_wins.each do |wr|
        wr.pool_placement_tiebreaker = 'Most Majors'
        add_points(wr)
      end
    end

    def coin_flip(wrestlers_with_same_points)
      wrestler = wrestlers_with_same_points.sample
      wrestler.pool_placement_tiebreaker = 'Coin Flip'
      add_points_to_wrestlers_ahead(wrestler)
      add_points(wrestler)
    end
  end
end
