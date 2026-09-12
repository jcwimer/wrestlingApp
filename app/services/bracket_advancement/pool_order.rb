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
      if (original_tie_size == 2) && same_tie_size_as_original?(original_tie_size,
                                                                wrestlers_with_same_points)
        head_to_head(wrestlers_with_same_points)
      end
      deducted_points(wrestlers_with_same_points) if same_tie_size_as_original?(
        original_tie_size, wrestlers_with_same_points
      )
      team_points(wrestlers_with_same_points) if same_tie_size_as_original?(original_tie_size,
                                                                            wrestlers_with_same_points)
      finish_points(wrestlers_with_same_points) if same_tie_size_as_original?(original_tie_size,
                                                                              wrestlers_with_same_points)
      most_techs(wrestlers_with_same_points) if same_tie_size_as_original?(original_tie_size,
                                                                           wrestlers_with_same_points)
      most_majors(wrestlers_with_same_points) if same_tie_size_as_original?(original_tie_size,
                                                                            wrestlers_with_same_points)
      most_decisions(wrestlers_with_same_points) if same_tie_size_as_original?(original_tie_size,
                                                                               wrestlers_with_same_points)
      most_pins_in_least_time(wrestlers_with_same_points) if same_tie_size_as_original?(
        original_tie_size, wrestlers_with_same_points
      )
      quickest_pin(wrestlers_with_same_points) if same_tie_size_as_original?(original_tie_size,
                                                                             wrestlers_with_same_points)
      decision_point_differential(wrestlers_with_same_points) if same_tie_size_as_original?(
        original_tie_size, wrestlers_with_same_points
      )
      coin_flip(wrestlers_with_same_points) if same_tie_size_as_original?(original_tie_size,
                                                                          wrestlers_with_same_points)
    end

    def head_to_head(wrestlers_with_same_points)
      first, second = wrestlers_with_same_points
      match = first.match_against(second).find { |candidate| candidate.bracket_position == 'Pool' }
      winner = wrestlers_with_same_points.find { |wrestler| wrestler.id == match&.winner_id }
      award_wrestlers([winner].compact, wrestlers_with_same_points, 'Head to Head')
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

    def deducted_points(wrestlers_with_same_points)
      award_lowest(wrestlers_with_same_points, 'Least Deducted Points', &:total_points_deducted)
    end

    def team_points(wrestlers_with_same_points)
      award_highest(wrestlers_with_same_points, 'Team Points', &:total_pool_points_for_pool_order)
    end

    def finish_points(wrestlers_with_same_points)
      award_highest(wrestlers_with_same_points, 'Fall/Default/Forfeit/DQ Points') do |wrestler|
        pool_wins_by_type(wrestler, 'Pin', 'Forfeit', 'Injury Default', 'Default', 'DQ')
      end
    end

    def most_techs(wrestlers_with_same_points)
      award_highest(wrestlers_with_same_points, 'Tech Fall Points') do |wrestler|
        pool_wins_by_type(wrestler, 'Tech Fall')
      end
    end

    def most_majors(wrestlers_with_same_points)
      award_highest(wrestlers_with_same_points, 'Major Decision Points') do |wrestler|
        pool_wins_by_type(wrestler, 'Major')
      end
    end

    def most_decisions(wrestlers_with_same_points)
      award_highest(wrestlers_with_same_points, 'Decision Points') do |wrestler|
        pool_wins_by_type(wrestler, 'Decision')
      end
    end

    def most_pins_in_least_time(wrestlers_with_same_points)
      award_highest(wrestlers_with_same_points, 'Most Pins in Least Time') do |wrestler|
        pins = pool_pin_wins(wrestler)
        [pins.size, -pins.sum(&:pin_time_in_seconds)]
      end
    end

    def quickest_pin(wrestlers_with_same_points)
      return unless wrestlers_with_same_points.any? { |wrestler| pool_pin_wins(wrestler).any? }

      award_lowest(wrestlers_with_same_points, 'Quickest Pin') do |wrestler|
        pool_pin_wins(wrestler).map(&:pin_time_in_seconds).min || Float::INFINITY
      end
    end

    def decision_point_differential(wrestlers_with_same_points)
      award_highest(wrestlers_with_same_points, 'Decision Point Differential') do |wrestler|
        wrestler.pool_matches.sum do |match|
          next 0 unless match.finished == 1 && match.win_type == 'Decision'

          first_score, second_score = match.score.delete(' ').split('-').map(&:to_i)
          margin = (first_score - second_score).abs
          match.winner_id == wrestler.id ? margin : -margin
        end
      end
    end

    def pool_wins_by_type(wrestler, *win_types)
      wrestler.pool_wins.count { |match| win_types.include?(match.win_type) }
    end

    def pool_pin_wins(wrestler)
      wrestler.pool_wins.select { |match| match.win_type == 'Pin' }
    end

    def award_highest(wrestlers, label, &)
      values = wrestlers.index_with(&)
      award_wrestlers(values.select { |_wrestler, value| value == values.values.max }.keys, wrestlers, label)
    end

    def award_lowest(wrestlers, label, &)
      values = wrestlers.index_with(&)
      award_wrestlers(values.select { |_wrestler, value| value == values.values.min }.keys, wrestlers, label)
    end

    def award_wrestlers(winners, tied_wrestlers, label)
      return if winners.empty? || winners.size == tied_wrestlers.size

      add_points_to_wrestlers_ahead(winners.first)
      winners.each do |wrestler|
        wrestler.pool_placement_tiebreaker = label
        add_points(wrestler)
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
