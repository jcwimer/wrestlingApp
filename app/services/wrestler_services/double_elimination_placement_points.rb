# frozen_string_literal: true

module WrestlerServices
  class DoubleEliminationPlacementPoints
    def initialize(wrestler)
      @wrestler = wrestler
      @number_of_placers = @wrestler.weight.tournament.number_of_placers
    end

    def calc_points
      if won_bracket_position_size('1/2').positive?
        WrestlerServices::PlacementPoints.new(@number_of_placers).first_place
      elsif bracket_position_size('1/2').positive?
        WrestlerServices::PlacementPoints.new(@number_of_placers).second_place
      elsif won_bracket_position_size('3/4').positive?
        WrestlerServices::PlacementPoints.new(@number_of_placers).third_place
      elsif bracket_position_size('3/4').positive?
        WrestlerServices::PlacementPoints.new(@number_of_placers).fourth_place
      elsif won_bracket_position_size('5/6').positive?
        WrestlerServices::PlacementPoints.new(@number_of_placers).fifth_place
      elsif (bracket_position_size('Semis').positive? || bracket_position_size('Conso Semis').positive?) && (@number_of_placers >= 6)
        WrestlerServices::PlacementPoints.new(@number_of_placers).sixth_place
      elsif won_bracket_position_size('7/8').positive?
        WrestlerServices::PlacementPoints.new(@number_of_placers).seventh_place
      elsif bracket_position_size('Conso Quarter').positive? && (@number_of_placers >= 8)
        WrestlerServices::PlacementPoints.new(@number_of_placers).eighth_place
      else
        0
      end
    end

    def bracket_position_size(bracket_position_name)
      @wrestler.all_matches.count { |m| m.bracket_position == bracket_position_name }
    end

    def won_bracket_position_size(bracket_position_name)
      @wrestler.matches_won.count { |m| m.bracket_position == bracket_position_name }
    end

    def bracket_placement_points(bracket_position_name)
      return 0 if bracket_position_name == 'Did not place'

      return unless @wrestler.participating_matches.where(bracket_position: bracket_position_name).any?

      points = Teampointadjust.find_by(tournament_id: @wrestler.weight.tournament.id,
                                       points_for_placement: bracket_position_name)
      nil unless points
      # ... existing code ...
    end
  end
end
