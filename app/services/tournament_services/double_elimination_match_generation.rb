class DoubleEliminationMatchGeneration
  def initialize(tournament)
    @tournament = tournament
  end

  def generate_matches
    #
    # PHASE 1: Generate matches (with local round definitions).
    #
    @tournament.weights.each do |weight|
      generate_matches_for_weight(weight)
    end

    #
    # PHASE 2: Align all rounds to match the largest bracket’s definitions.
    #
    align_all_rounds_to_largest_bracket
  end

  ###########################################################################
  # PHASE 1: Generate all matches for each bracket, using a single definition.
  ###########################################################################
  def generate_matches_for_weight(weight)
    bracket_size = weight.calculate_bracket_size
    bracket_info = define_bracket_matches(bracket_size)
    return unless bracket_info

    # 1) Round one matchups
    bracket_info[:round_one_matchups].each_with_index do |matchup, idx|
      seed1, seed2       = matchup[:seeds]
      bracket_position   = matchup[:bracket_position]
      bracket_pos_number = idx + 1
      round_number       = matchup[:round]

      create_matchup_from_seed(
        seed1,
        seed2,
        bracket_position,
        bracket_pos_number,
        round_number,
        weight
      )
    end

    # 2) Championship rounds
    bracket_info[:championship_rounds].each do |round_info|
      bracket_position   = round_info[:bracket_position]
      matches_this_round = round_info[:number_of_matches]
      round_number       = round_info[:round]

      matches_this_round.times do |i|
        create_matchup(
          nil,
          nil,
          bracket_position,
          i + 1,
          round_number,
          weight
        )
      end
    end

    # 3) Consolation rounds
    bracket_info[:consolation_rounds].each do |round_info|
      bracket_position   = round_info[:bracket_position]
      matches_this_round = round_info[:number_of_matches]
      round_number       = round_info[:round]

      matches_this_round.times do |i|
        create_matchup(
          nil,
          nil,
          bracket_position,
          i + 1,
          round_number,
          weight
        )
      end

      # 5/6, 7/8 placing logic
      if weight.wrestlers.size >= 5 && @tournament.number_of_placers >= 6 && matches_this_round == 1
        create_matchup(nil, nil, "5/6", 1, round_number, weight)
      end
      if weight.wrestlers.size >= 7 && @tournament.number_of_placers >= 8 && matches_this_round == 1
        create_matchup(nil, nil, "7/8", 1, round_number, weight)
      end
    end
  end

  # Single bracket definition dynamically generated for any power-of-two bracket size.
  # Returns a hash with :round_one_matchups, :championship_rounds, and :consolation_rounds.
  def define_bracket_matches(bracket_size)
    # Only support brackets that are powers of two
    return nil unless (bracket_size & (bracket_size - 1)).zero?

    # 1) Generate the seed sequence (e.g., [1,8,5,4,...] for size=8)
    seeds = generate_seed_sequence(bracket_size)

    # 2) Pair seeds into first-round matchups, sorting so lower seed is w1
    round_one = seeds.each_slice(2).map.with_index do |(s1, s2), idx|
      a, b = [s1, s2].sort
      {
        seeds:            [a, b],
        bracket_position: first_round_label(bracket_size),
        round:            1
      }
    end

    # 3) Build full structure, including dynamic championship & consolation rounds
    {
      round_one_matchups:  round_one,
      championship_rounds: dynamic_championship_rounds(bracket_size),
      consolation_rounds:  dynamic_consolation_rounds(bracket_size)
    }
  end

  # Returns a human-readable label for the first round based on bracket size.
  def first_round_label(bracket_size)
    case bracket_size
    when 2 then "1/2"
    when 4 then "Semis"
    when 8 then "Quarter"
    else       "Bracket Round of #{bracket_size}"
    end
  end

  # Dynamically generate championship rounds for any power-of-two bracket size.
  def dynamic_championship_rounds(bracket_size)
    rounds = []
    num_rounds = Math.log2(bracket_size).to_i
    # i: 1 -> first post-initial round, up to num_rounds-1 (final)
    (1...num_rounds).each do |i|
      participants       = bracket_size / (2**i)
      number_of_matches  = participants / 2
      bracket_position   = case participants
                           when 2 then "1/2"
                           when 4 then "Semis"
                           when 8 then "Quarter"
                           else       "Bracket Round of #{participants}"
                           end
      round_number       = i * 2
      rounds << { bracket_position: bracket_position,
                  number_of_matches: number_of_matches,
                  round:             round_number }
    end
    rounds
  end

  # Dynamically generate consolation rounds for any power-of-two bracket size.
  def dynamic_consolation_rounds(bracket_size)
    rounds = []
    num_rounds = Math.log2(bracket_size).to_i
    total_conso = 2 * (num_rounds - 1) - 1
    (1..total_conso).each do |j|
      participants       = bracket_size / (2**((j.to_f / 2).ceil))
      number_of_matches  = participants / 2
      bracket_position = case participants
                         when 2 then "3/4"
                         when 4
                           j.odd? ? "Conso Quarter" : "Conso Semis"
                         else
                           suffix = j.odd? ? ".1" : ".2"
                           "Conso Round of #{participants}#{suffix}"
                         end
      round_number       = j + 1
      rounds << { bracket_position:    bracket_position,
                  number_of_matches:   number_of_matches,
                  round:               round_number }
    end
    rounds
  end

  ###########################################################################
  # PHASE 2: Overwrite rounds in all smaller brackets to match the largest one.
  ###########################################################################
  def align_all_rounds_to_largest_bracket
    largest_weight = @tournament.weights.max_by { |w| w.calculate_bracket_size }
    return unless largest_weight

    position_to_round = {}
    largest_weight.tournament.matches.where(weight_id: largest_weight.id).each do |m|
      position_to_round[m.bracket_position] ||= m.round
    end

    @tournament.matches.find_each do |match|
      if position_to_round.key?(match.bracket_position)
        match.update(round: position_to_round[match.bracket_position])
      end
    end
  end

  ###########################################################################
  # Helper methods
  ###########################################################################
  def wrestler_with_seed(seed, weight)
    Wrestler.where("weight_id = ? AND bracket_line = ?", weight.id, seed).first&.id
  end

  def create_matchup_from_seed(w1_seed, w2_seed, bracket_position, bracket_position_number, round, weight)
    create_matchup(
      wrestler_with_seed(w1_seed, weight),
      wrestler_with_seed(w2_seed, weight),
      bracket_position,
      bracket_position_number,
      round,
      weight
    )
  end

  def create_matchup(w1, w2, bracket_position, bracket_position_number, round, weight)
    weight.tournament.matches.create!(
      w1: w1,
      w2: w2,
      weight_id: weight.id,
      round: round,
      bracket_position: bracket_position,
      bracket_position_number: bracket_position_number
    )
  end

  # Calculates the sequence of seeds for the first round of a power-of-two bracket.
  def generate_seed_sequence(n)
    raise ArgumentError, "Bracket size must be a power of two" unless (n & (n - 1)).zero?
    return [1, 2] if n == 2

    half = n / 2
    prev = generate_seed_sequence(half)
    comp = prev.map { |s| n + 1 - s }

    result = []
    (0...prev.size).step(2) do |k|
      result << prev[k]
      result << comp[k]
      result << comp[k + 1]
      result << prev[k + 1]
    end
    result
  end
end
