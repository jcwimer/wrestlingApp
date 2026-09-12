# frozen_string_literal: true

module TournamentServices
  class PoolToBracketMatchGeneration
    def initialize(tournament, weights: nil, wrestlers_by_weight_id: nil)
      @tournament = tournament
      @weights = weights
      @wrestlers_by_weight_id = wrestlers_by_weight_id
    end

    def generate_pool_to_bracket_matches
      rows = []
      generation_weights.each do |weight|
        wrestlers = wrestlers_for_weight(weight)
        pool_rows = TournamentServices::PoolGeneration.new(weight, wrestlers: wrestlers).generate_pools
        rows.concat(pool_rows)

        highest_round = pool_rows.map { |row| row[:round] }.max || 0
        bracket_rows = TournamentServices::PoolBracketGeneration.new(weight, highest_round).generate_bracket_matches
        rows.concat(bracket_rows)
      end

      move_pool_seeds_to_final_pool_round(rows)
      rows
    end

    def move_pool_seeds_to_final_pool_round(match_rows)
      generation_weights.each do |w|
        set_original_seeds_to_wrestle_last_pool_round(w, match_rows)
      end
    end

    def set_original_seeds_to_wrestle_last_pool_round(weight, match_rows)
      pool = 1
      wrestlers = wrestlers_for_weight(weight)
      weight_pools = weight.pools
      until pool > weight_pools
        pool_wrestlers = wrestlers.select { |w| w.pool == pool }.sort_by(&:bracket_line)
        wrestler1 = pool_wrestlers.first
        wrestler2 = pool_wrestlers.second
        if wrestler1 && wrestler2
          pool_matches = match_rows.select do |row|
            row[:weight_id] == weight.id && row[:bracket_position] == 'Pool' && (row[:w1] == wrestler1.id || row[:w2] == wrestler1.id)
          end
          match = pool_matches.max_by { |row| row[:round] }
          if match && (match[:w1] != wrestler2.id || match[:w2] != wrestler2.id)
            if match[:w1] == wrestler1.id
              swap_wrestlers_in_memory(match_rows, wrestlers, match[:w2], wrestler2.id)
            elsif match[:w2] == wrestler1.id
              swap_wrestlers_in_memory(match_rows, wrestlers, match[:w1], wrestler2.id)
            end
          end
        end
        pool += 1
      end
    end

    def swap_wrestlers_in_memory(match_rows, wrestlers, wrestler1_id, wrestler2_id)
      w1 = wrestlers.find { |w| w.id == wrestler1_id }
      w2 = wrestlers.find { |w| w.id == wrestler2_id }
      return unless w1 && w2

      w1_bracket_line = w1.bracket_line
      w1_pool = w1.pool
      w1.bracket_line = w2.bracket_line
      w1.pool = w2.pool
      w2.bracket_line = w1_bracket_line
      w2.pool = w1_pool

      swap_match_rows(match_rows, wrestler1_id, wrestler2_id)
    end

    def swap_match_rows(match_rows, wrestler1_id, wrestler2_id)
      match_rows.each do |row|
        row[:w1] = swap_id(row[:w1], wrestler1_id, wrestler2_id)
        row[:w2] = swap_id(row[:w2], wrestler1_id, wrestler2_id)
        row[:winner_id] = swap_id(row[:winner_id], wrestler1_id, wrestler2_id)
      end
    end

    def swap_id(value, wrestler1_id, wrestler2_id)
      return wrestler2_id if value == wrestler1_id
      return wrestler1_id if value == wrestler2_id

      value
    end

    def generation_weights
      @weights || @tournament.weights.order(:max).to_a
    end

    def wrestlers_for_weight(weight)
      @wrestlers_by_weight_id&.fetch(weight.id, nil) || weight.wrestlers.to_a
    end

    def assign_loser_names
      TournamentServices::PoolToBracketGenerateLoserNames.new(@tournament).assign_loser_names
    end
  end
end
