# frozen_string_literal: true

module WrestlerServices
  class PlacementPoints
    def initialize(number_of_placers)
      @number_of_placers = number_of_placers
    end

    def first_place
      return 14 if @number_of_placers == 4

      16
    end

    def second_place
      return 10 if @number_of_placers == 4

      12
    end

    def third_place
      return 7 if @number_of_placers == 4

      9
    end

    def fourth_place
      return 4 if @number_of_placers == 4

      7
    end

    def fifth_place
      5
    end

    def sixth_place
      3
    end

    def seventh_place
      2
    end

    def eighth_place
      1
    end
  end
end
