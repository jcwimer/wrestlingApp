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
    # Use a hash instead of Struct
    case bracket_size
    when 4
      {
        round_one_matchups: [[1, 4, "Semis"], [2, 3, "Semis"]],
        championship_rounds: [[2, 1, "1/2"]],
        consolation_rounds: [[2, 1, "3/4"]]
      }
    when 8
      {
        round_one_matchups: [
          [1, 8, "Quarter"], [4, 5, "Quarter"], [3, 6, "Quarter"], [2, 7, "Quarter"]
        ],
        championship_rounds: [
          [2, 2, "Semis"], [4, 1, "1/2"]
        ],
        consolation_rounds: [
          [2, 2, "Conso Quarter"], [3, 2, "Conso Semis"], [4, 1, "3/4"]
        ]
      }
    when 16
      {
        round_one_matchups: [
          [1, 16, "Bracket"], [8, 9, "Bracket"], [5, 12, "Bracket"], [4, 13, "Bracket"],
          [3, 14, "Bracket"], [6, 11, "Bracket"], [7, 10, "Bracket"], [2, 15, "Bracket"]
        ],
        championship_rounds: [
          [2, 4, "Quarter"], [4, 2, "Semis"], [6, 1, "1/2"]
        ],
        consolation_rounds: [
          [2, 4, "Conso"], [3, 4, "Conso"], [4, 2, "Conso Quarter"], 
          [5, 2, "Conso Semis"], [6, 1, "3/4"]
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
      matches_this_round = bracket_matches[:round_one_matchups].size
      bracket_position = matchup[2]
      create_matchup_from_seed(
        matchup[0],
        matchup[1],
        bracket_position,
        index + 1,
        1,
        weight
      )
    end

    # Generate remaining championship rounds
    bracket_matches[:championship_rounds].each do |matchup|
      round = matchup[0]
      matches_this_round = matchup[1]
      bracket_position = matchup[2]

      matches_this_round.times do |bracket_position_number|
        create_matchup(nil, nil, bracket_position, bracket_position_number + 1, round, weight)
      end
    end

    # Generate consolation matches
    bracket_matches[:consolation_rounds].each do |matchup|
      round = matchup[0]
      matches_this_round = matchup[1]
      bracket_position = matchup[2]

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
    