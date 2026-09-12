# frozen_string_literal: true

module WrestlerServices
  class PoolBracketPlacementPoints
    def initialize(wrestler)
      @wrestler = wrestler
      @bracket = wrestler.weight.pool_bracket_type
      # reverse is needed below for descending order
      @largest_bracket = wrestler.weight.tournament.weights.max_by { |w| w.wrestlers.size }.pool_bracket_type
    end

    def calc_points
      @points = 0
      while_points_are_zero { @points = final_match_points }
      while_points_are_zero { @points = two_pools_to_semi } if @bracket == 'twoPoolsToSemi'
      while_points_are_zero { @points = four_pools_to_quarter } if (@bracket == 'fourPoolsToQuarter') || (@bracket == 'eightPoolsToQuarter')
      while_points_are_zero { @points = four_pools_to_semi } if @bracket == 'fourPoolsToSemi'
      while_points_are_zero { @points = one_pool } if @wrestler.weight.wrestlers.size <= 6 && @wrestler.weight.all_pool_matches_finished?(1)
      @points
    end

    def number_of_placers
      if (@largest_bracket == 'twoPoolsToSemi') || (@largest_bracket == 'twoPoolsToFinal') || (@largest_bracket == 'onePool')
        4
      else
        8
      end
    end

    def while_points_are_zero
      return unless @points.zero?

      yield
    end

    def bracket_position_size(bracket_position_name)
      @wrestler.all_matches.count { |m| m.bracket_position == bracket_position_name }
    end

    def won_bracket_position_size(bracket_position_name)
      @wrestler.matches_won.count { |m| m.bracket_position == bracket_position_name }
    end

    def four_pools_to_quarter
      return WrestlerServices::PlacementPoints.new(number_of_placers).fourth_place if bracket_position_size('Semis').positive?
      return WrestlerServices::PlacementPoints.new(number_of_placers).eighth_place if bracket_position_size('Quarter').positive?

      0
    end

    def two_pools_to_semi
      return WrestlerServices::PlacementPoints.new(number_of_placers).fourth_place if bracket_position_size('Semis').positive?
      return WrestlerServices::PlacementPoints.new(number_of_placers).eighth_place if bracket_position_size('Conso Semis').positive?

      0
    end

    def four_pools_to_semi
      return WrestlerServices::PlacementPoints.new(number_of_placers).fourth_place if bracket_position_size('Semis').positive?
      return WrestlerServices::PlacementPoints.new(number_of_placers).eighth_place if bracket_position_size('Conso Semis').positive?

      0
    end

    def one_pool
      case @wrestler.pool_placement
      when 1
        return WrestlerServices::PlacementPoints.new(number_of_placers).first_place
      when 2
        return WrestlerServices::PlacementPoints.new(number_of_placers).second_place
      when 3
        return WrestlerServices::PlacementPoints.new(number_of_placers).third_place
      when 4
        return WrestlerServices::PlacementPoints.new(number_of_placers).fourth_place
      end

      0
    end

    def final_match_points
      return WrestlerServices::PlacementPoints.new(number_of_placers).first_place if won_bracket_position_size('1/2').positive?
      return WrestlerServices::PlacementPoints.new(number_of_placers).third_place if won_bracket_position_size('3/4').positive?
      return WrestlerServices::PlacementPoints.new(number_of_placers).fifth_place if won_bracket_position_size('5/6').positive?
      return WrestlerServices::PlacementPoints.new(number_of_placers).seventh_place if won_bracket_position_size('7/8').positive?
      return WrestlerServices::PlacementPoints.new(number_of_placers).second_place if bracket_position_size('1/2').positive?
      return WrestlerServices::PlacementPoints.new(number_of_placers).fourth_place if bracket_position_size('3/4').positive?
      return WrestlerServices::PlacementPoints.new(number_of_placers).sixth_place if bracket_position_size('5/6').positive?
      return WrestlerServices::PlacementPoints.new(number_of_placers).eighth_place if bracket_position_size('7/8').positive?

      0
    end
  end
end
