# frozen_string_literal: true

module TournamentServices
  class PoolBracketGeneration
    def initialize(weight, highest_round)
      @weight = weight
      @tournament = @weight.tournament
      @pool_bracket_type = @weight.pool_bracket_type
      @round = highest_round + 1
    end

    def next_round
      @round += 1
    end

    def generate_bracket_matches
      @rows = []
      case @pool_bracket_type
      when 'twoPoolsToSemi'
        two_pools_to_semi
      when 'twoPoolsToFinal'
        two_pools_to_final
      when 'fourPoolsToQuarter'
        four_pools_to_quarter
      when 'fourPoolsToSemi'
        four_pools_to_semi
      when 'eightPoolsToQuarter'
        eight_pools_to_quarter
      end
      @rows
    end

    def two_pools_to_semi
      create_matchup('Winner Pool 1', 'Runner Up Pool 2', 'Semis', 1)
      create_matchup('Winner Pool 2', 'Runner Up Pool 1', 'Semis', 2)
      next_round
      create_matchup('', '', '1/2', 1)
      create_matchup('', '', '3/4', 1)
    end

    def two_pools_to_final
      create_matchup('Winner Pool 1', 'Winner Pool 2', '1/2', 1)
      create_matchup('Runner Up Pool 1', 'Runner Up Pool 2', '3/4', 1)
    end

    def four_pools_to_quarter
      create_matchup('Winner Pool 1', 'Runner Up Pool 2', 'Quarter', 1)
      create_matchup('Winner Pool 4', 'Runner Up Pool 3', 'Quarter', 2)
      create_matchup('Winner Pool 2', 'Runner Up Pool 1', 'Quarter', 3)
      create_matchup('Winner Pool 3', 'Runner Up Pool 4', 'Quarter', 4)
      next_round
      create_matchup('', '', 'Semis', 1)
      create_matchup('', '', 'Semis', 2)
      create_matchup('', '', 'Conso Semis', 1)
      create_matchup('', '', 'Conso Semis', 2)
      next_round
      create_matchup('', '', '1/2', 1)
      create_matchup('', '', '3/4', 1)
      create_matchup('', '', '5/6', 1)
      create_matchup('', '', '7/8', 1)
    end

    def four_pools_to_semi
      create_matchup('Winner Pool 1', 'Winner Pool 4', 'Semis', 1)
      create_matchup('Winner Pool 2', 'Winner Pool 3', 'Semis', 2)
      create_matchup('Runner Up Pool 1', 'Runner Up Pool 4', 'Conso Semis', 1)
      create_matchup('Runner Up Pool 2', 'Runner Up Pool 3', 'Conso Semis', 2)
      next_round
      create_matchup('', '', '1/2', 1)
      create_matchup('', '', '3/4', 1)
      create_matchup('', '', '5/6', 1)
      create_matchup('', '', '7/8', 1)
    end

    def eight_pools_to_quarter
      create_matchup('Winner Pool 1', 'Winner Pool 8', 'Quarter', 1)
      create_matchup('Winner Pool 4', 'Winner Pool 5', 'Quarter', 2)
      create_matchup('Winner Pool 2', 'Winner Pool 7', 'Quarter', 3)
      create_matchup('Winner Pool 3', 'Winner Pool 6', 'Quarter', 4)
      next_round
      create_matchup('', '', 'Semis', 1)
      create_matchup('', '', 'Semis', 2)
      create_matchup('', '', 'Conso Semis', 1)
      create_matchup('', '', 'Conso Semis', 2)
      next_round
      create_matchup('', '', '1/2', 1)
      create_matchup('', '', '3/4', 1)
      create_matchup('', '', '5/6', 1)
      create_matchup('', '', '7/8', 1)
    end

    def create_matchup(w1_name, w2_name, bracket_position, bracket_position_number)
      @rows << {
        loser1_name: w1_name,
        loser2_name: w2_name,
        tournament_id: @tournament.id,
        weight_id: @weight.id,
        round: @round,
        bracket_position: bracket_position,
        bracket_position_number: bracket_position_number
      }
    end
  end
end
