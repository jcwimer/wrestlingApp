class DoubleEliminationMatchGeneration
  def initialize(tournament)
    @tournament = tournament
  end

  def generate_matches
    @tournament.weights.each do |weight|
      generate_matches_for_weight(weight)
    end
  end

  def define_bracket_matches(bracket_size)
    # Use detailed hashes for rounds, number of matches, and bracket positions
    case bracket_size
    when 4
      {
        round_one_matchups: [
          { seeds: [1, 4], bracket_position: "Semis" }, { seeds: [2, 3], bracket_position: "Semis" }
        ],
        championship_rounds: [
          { round: 2, number_of_matches: 1, bracket_position: "1/2" }
        ],
        consolation_rounds: [
          { round: 2, number_of_matches: 1, bracket_position: "3/4" }
        ]
      }
    when 8
      {
        round_one_matchups: [
          { seeds: [1, 8], bracket_position: "Quarter" }, { seeds: [4, 5], bracket_position: "Quarter" },
          { seeds: [3, 6], bracket_position: "Quarter" }, { seeds: [2, 7], bracket_position: "Quarter" }
        ],
        championship_rounds: [
          { round: 2, number_of_matches: 2, bracket_position: "Semis" }, { round: 4, number_of_matches: 1, bracket_position: "1/2" }
        ],
        consolation_rounds: [
          { round: 2, number_of_matches: 2, bracket_position: "Conso Quarter" }, { round: 3, number_of_matches: 2, bracket_position: "Conso Semis" }, { round: 4, number_of_matches: 1, bracket_position: "3/4" }
        ]
      }
    when 16
      {
        round_one_matchups: [
          { seeds: [1, 16], bracket_position: "Bracket" }, { seeds: [8, 9], bracket_position: "Bracket" }, { seeds: [5, 12], bracket_position: "Bracket" }, { seeds: [4, 13], bracket_position: "Bracket" },
          { seeds: [3, 14], bracket_position: "Bracket" }, { seeds: [6, 11], bracket_position: "Bracket" },{ seeds: [7, 10], bracket_position: "Bracket" }, { seeds: [2, 15], bracket_position: "Bracket" }
        ],
        championship_rounds: [
          { round: 2, number_of_matches: 4, bracket_position: "Quarter" }, { round: 4, number_of_matches: 2, bracket_position: "Semis" }, { round: 6, number_of_matches: 1, bracket_position: "1/2" }
        ],
        consolation_rounds: [
          { round: 2, number_of_matches: 4, bracket_position: "Conso" }, { round: 3, number_of_matches: 4, bracket_position: "Conso" }, { round: 4, number_of_matches: 2, bracket_position: "Conso Quarter" },
          { round: 5, number_of_matches: 2, bracket_position: "Conso Semis" }, { round: 6, number_of_matches: 1, bracket_position: "3/4" }
        ]
      }
    when 32
      {
        round_one_matchups: [
          { seeds: [1, 32], bracket_position: "Bracket" }, { seeds: [16, 17], bracket_position: "Bracket" }, { seeds: [9, 24], bracket_position: "Bracket" }, { seeds: [8, 25], bracket_position: "Bracket" },
          { seeds: [5, 28], bracket_position: "Bracket" }, { seeds: [12, 21], bracket_position: "Bracket" }, { seeds: [13, 20], bracket_position: "Bracket" }, { seeds: [4, 29], bracket_position: "Bracket" },
          { seeds: [3, 30], bracket_position: "Bracket" }, { seeds: [14, 19], bracket_position: "Bracket" }, { seeds: [11, 22], bracket_position: "Bracket" }, { seeds: [6, 27], bracket_position: "Bracket" },
          { seeds: [7, 26], bracket_position: "Bracket" }, { seeds: [10, 23], bracket_position: "Bracket" }, { seeds: [15, 18], bracket_position: "Bracket" }, { seeds: [2, 31], bracket_position: "Bracket" }
        ],
        championship_rounds: [
          { round: 2, number_of_matches: 8, bracket_position: "Bracket" }, { round: 4, number_of_matches: 4, bracket_position: "Quarter" },
          { round: 6, number_of_matches: 2, bracket_position: "Semis" }, { round: 8, number_of_matches: 1, bracket_position: "1/2" }
        ],
        consolation_rounds: [
          { round: 2, number_of_matches: 8, bracket_position: "Conso" }, { round: 3, number_of_matches: 8, bracket_position: "Conso" }, { round: 4, number_of_matches: 4, bracket_position: "Conso" }, { round: 5, number_of_matches: 4, bracket_position: "Conso" },
          { round: 6, number_of_matches: 2, bracket_position: "Conso Quarter" }, { round: 7, number_of_matches: 2, bracket_position: "Conso Semis" }, { round: 8, number_of_matches: 1, bracket_position: "3/4" }
        ]
      }
    else
      nil
    end
  end

  def generate_matches_for_weight(weight)
    number_of_placers = @tournament.number_of_placers
    bracket_size = weight.calculate_bracket_size
    bracket_matches = define_bracket_matches(bracket_size)
  
    # Generate round 1 matches
    bracket_matches[:round_one_matchups].each_with_index do |matchup, index|
      seed_1 = matchup[:seeds][0]
      seed_2 = matchup[:seeds][1]
      bracket_position = matchup[:bracket_position]
      round = 1
      bracket_position_number = index + 1
  
      create_matchup_from_seed(seed_1, seed_2, bracket_position, bracket_position_number, round, weight)
    end
  
    # Generate remaining championship rounds
    bracket_matches[:championship_rounds].each do |round_info|
      round = round_info[:round]
      matches_this_round = round_info[:number_of_matches]
      bracket_position = round_info[:bracket_position]
  
      matches_this_round.times do |bracket_position_number|
        create_matchup(nil, nil, bracket_position, bracket_position_number + 1, round, weight)
      end
    end
  
    # Generate consolation matches
    bracket_matches[:consolation_rounds].each do |round_info|
      round = round_info[:round]
      matches_this_round = round_info[:number_of_matches]
      bracket_position = round_info[:bracket_position]
  
      matches_this_round.times do |bracket_position_number|
        create_matchup(nil, nil, bracket_position, bracket_position_number + 1, round, weight)
      end
  
      if weight.wrestlers.size >= 5
        create_matchup(nil, nil, "5/6", 1, round, weight) if @tournament.number_of_placers >= 6 && matches_this_round == 1
      end
  
      if weight.wrestlers.size >= 7
        create_matchup(nil, nil, "7/8", 1, round, weight) if @tournament.number_of_placers >= 8 && matches_this_round == 1
      end
    end
  end

  def wrestler_with_seed(seed, weight)
    wrestler = Wrestler.where("weight_id = ? and bracket_line = ?", weight.id, seed).first
    wrestler&.id
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
    weight.tournament.matches.create(
      w1: w1,
      w2: w2,
      weight_id: weight.id,
      round: round,
      bracket_position: bracket_position,
      bracket_position_number: bracket_position_number
    )
  end

    #### Logic below works but not used. Could not find a way to reliably determine a couple things.
    # For example, properly forcing the semis to be after round 2 of consolations in a 16 man bracket.
    # and properly calculating the number of matches in a round for the consolation rounds.

  def calculate_championship_rounds(bracket_size)
    return nil if bracket_size <= 0 # Handle invalid input

    Math.log2(bracket_size).to_i
  end

  def calculate_consolation_rounds(bracket_size)
    return nil if bracket_size <= 0 || !bracket_size.is_a?(Integer)

    championship_rounds = calculate_championship_rounds(bracket_size)
    return 1 if championship_rounds == 2
    return 0 if championship_rounds == 1

    extra_powers_of_two = championship_rounds - 3
    championship_rounds + extra_powers_of_two
  end
end
    