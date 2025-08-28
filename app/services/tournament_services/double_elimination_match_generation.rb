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
      seed1, seed2         = matchup[:seeds]
      bracket_position     = matchup[:bracket_position]
      bracket_pos_number   = idx + 1
      round_number         = matchup[:round]  # Use the round from our definition

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

      #
      # 5/6, 7/8 placing logic
      #
      if weight.wrestlers.size >= 5
        if @tournament.number_of_placers >= 6 && matches_this_round == 1
          create_matchup(nil, nil, "5/6", 1, round_number, weight)
        end
      end
      if weight.wrestlers.size >= 7
        if @tournament.number_of_placers >= 8 && matches_this_round == 1
          create_matchup(nil, nil, "7/8", 1, round_number, weight)
        end
      end
    end
  end

  #
  # Single bracket definition that includes both bracket_position and round.
  # If you later decide to tweak round numbering, you do it in ONE place.
  #
  def define_bracket_matches(bracket_size)
    case bracket_size
    when 4
      {
        round_one_matchups: [
          # First round is Semis => round=1
          { seeds: [1, 4], bracket_position: "Semis", round: 1 },
          { seeds: [2, 3], bracket_position: "Semis", round: 1 }
        ],
        championship_rounds: [
          # Final => round=2
          { bracket_position: "1/2", number_of_matches: 1, round: 2 }
        ],
        consolation_rounds: [
          # 3rd place => round=2
          { bracket_position: "3/4", number_of_matches: 1, round: 2 }
        ]
      }

    when 8
      {
        round_one_matchups: [
          # Quarter => round=1
          { seeds: [1, 8], bracket_position: "Quarter", round: 1 },
          { seeds: [4, 5], bracket_position: "Quarter", round: 1 },
          { seeds: [3, 6], bracket_position: "Quarter", round: 1 },
          { seeds: [2, 7], bracket_position: "Quarter", round: 1 }
        ],
        championship_rounds: [
          # Semis => round=2, Final => round=4
          { bracket_position: "Semis", number_of_matches: 2, round: 2 },
          { bracket_position: "1/2",   number_of_matches: 1, round: 4 }
        ],
        consolation_rounds: [
          # Conso Quarter => round=2, Conso Semis => round=3, 3/4 => round=4
          { bracket_position: "Conso Quarter", number_of_matches: 2, round: 2 },
          { bracket_position: "Conso Semis",   number_of_matches: 2, round: 3 },
          { bracket_position: "3/4",           number_of_matches: 1, round: 4 }
        ]
      }

    when 16
      {
        round_one_matchups: [
          { seeds: [1,16], bracket_position: "Bracket Round of 16", round: 1 },
          { seeds: [8,9],  bracket_position: "Bracket Round of 16", round: 1 },
          { seeds: [5,12], bracket_position: "Bracket Round of 16", round: 1 },
          { seeds: [4,13], bracket_position: "Bracket Round of 16", round: 1 },
          { seeds: [3,14], bracket_position: "Bracket Round of 16", round: 1 },
          { seeds: [6,11], bracket_position: "Bracket Round of 16", round: 1 },
          { seeds: [7,10], bracket_position: "Bracket Round of 16", round: 1 },
          { seeds: [2,15], bracket_position: "Bracket Round of 16", round: 1 }
        ],
        championship_rounds: [
          # Quarter => round=2, Semis => round=4, Final => round=6
          { bracket_position: "Quarter", number_of_matches: 4, round: 2 },
          { bracket_position: "Semis",   number_of_matches: 2, round: 4 },
          { bracket_position: "1/2",     number_of_matches: 1, round: 6 }
        ],
        consolation_rounds: [
          # Just carry over your standard numbering
          { bracket_position: "Conso Round of 8.1", number_of_matches: 4, round: 2 },
          { bracket_position: "Conso Round of 8.2", number_of_matches: 4, round: 3 },
          { bracket_position: "Conso Quarter",      number_of_matches: 2, round: 4 },
          { bracket_position: "Conso Semis",        number_of_matches: 2, round: 5 },
          { bracket_position: "3/4",                number_of_matches: 1, round: 6 }
        ]
      }

    when 32
      {
        round_one_matchups: [
          { seeds: [1,32],   bracket_position: "Bracket Round of 32", round: 1 },
          { seeds: [16,17],  bracket_position: "Bracket Round of 32", round: 1 },
          { seeds: [9,24],   bracket_position: "Bracket Round of 32", round: 1 },
          { seeds: [8,25],   bracket_position: "Bracket Round of 32", round: 1 },
          { seeds: [5,28],   bracket_position: "Bracket Round of 32", round: 1 },
          { seeds: [12,21],  bracket_position: "Bracket Round of 32", round: 1 },
          { seeds: [13,20],  bracket_position: "Bracket Round of 32", round: 1 },
          { seeds: [4,29],   bracket_position: "Bracket Round of 32", round: 1 },
          { seeds: [3,30],   bracket_position: "Bracket Round of 32", round: 1 },
          { seeds: [14,19],  bracket_position: "Bracket Round of 32", round: 1 },
          { seeds: [11,22],  bracket_position: "Bracket Round of 32", round: 1 },
          { seeds: [6,27],   bracket_position: "Bracket Round of 32", round: 1 },
          { seeds: [7,26],   bracket_position: "Bracket Round of 32", round: 1 },
          { seeds: [10,23],  bracket_position: "Bracket Round of 32", round: 1 },
          { seeds: [15,18],  bracket_position: "Bracket Round of 32", round: 1 },
          { seeds: [2,31],   bracket_position: "Bracket Round of 32", round: 1 }
        ],
        championship_rounds: [
          { bracket_position: "Bracket Round of 16", number_of_matches: 8, round: 2 },
          { bracket_position: "Quarter",             number_of_matches: 4, round: 4 },
          { bracket_position: "Semis",               number_of_matches: 2, round: 6 },
          { bracket_position: "1/2",                 number_of_matches: 1, round: 8 }
        ],
        consolation_rounds: [
          { bracket_position: "Conso Round of 16.1", number_of_matches: 8, round: 2 },
          { bracket_position: "Conso Round of 16.2", number_of_matches: 8, round: 3 },
          { bracket_position: "Conso Round of 8.1",  number_of_matches: 4, round: 4 },
          { bracket_position: "Conso Round of 8.2",  number_of_matches: 4, round: 5 },
          { bracket_position: "Conso Quarter",       number_of_matches: 2, round: 6 },
          { bracket_position: "Conso Semis",         number_of_matches: 2, round: 7 },
          { bracket_position: "3/4",                 number_of_matches: 1, round: 8 }
        ]
      }
    when 64
      {
        round_one_matchups: [
          { seeds: [1, 64], bracket_position: "Bracket Round of 64", round: 1 },
          { seeds: [32, 33], bracket_position: "Bracket Round of 64", round: 1 },
          { seeds: [17, 48], bracket_position: "Bracket Round of 64", round: 1 },
          { seeds: [16, 49], bracket_position: "Bracket Round of 64", round: 1 },
          { seeds: [9, 56], bracket_position: "Bracket Round of 64", round: 1 },
          { seeds: [24, 41], bracket_position: "Bracket Round of 64", round: 1 },
          { seeds: [25, 40], bracket_position: "Bracket Round of 64", round: 1 },
          { seeds: [8, 57], bracket_position: "Bracket Round of 64", round: 1 },
          { seeds: [5, 60], bracket_position: "Bracket Round of 64", round: 1 },
          { seeds: [28, 37], bracket_position: "Bracket Round of 64", round: 1 },
          { seeds: [21, 44], bracket_position: "Bracket Round of 64", round: 1 },
          { seeds: [12, 53], bracket_position: "Bracket Round of 64", round: 1 },
          { seeds: [13, 52], bracket_position: "Bracket Round of 64", round: 1 },
          { seeds: [20, 45], bracket_position: "Bracket Round of 64", round: 1 },
          { seeds: [29, 36], bracket_position: "Bracket Round of 64", round: 1 },
          { seeds: [4, 61], bracket_position: "Bracket Round of 64", round: 1 },
          { seeds: [3, 62], bracket_position: "Bracket Round of 64", round: 1 },
          { seeds: [30, 35], bracket_position: "Bracket Round of 64", round: 1 },
          { seeds: [19, 46], bracket_position: "Bracket Round of 64", round: 1 },
          { seeds: [14, 51], bracket_position: "Bracket Round of 64", round: 1 },
          { seeds: [11, 54], bracket_position: "Bracket Round of 64", round: 1 },
          { seeds: [22, 43], bracket_position: "Bracket Round of 64", round: 1 },
          { seeds: [27, 38], bracket_position: "Bracket Round of 64", round: 1 },
          { seeds: [6, 59], bracket_position: "Bracket Round of 64", round: 1 },
          { seeds: [7, 58], bracket_position: "Bracket Round of 64", round: 1 },
          { seeds: [26, 39], bracket_position: "Bracket Round of 64", round: 1 },
          { seeds: [23, 42], bracket_position: "Bracket Round of 64", round: 1 },
          { seeds: [10, 55], bracket_position: "Bracket Round of 64", round: 1 },
          { seeds: [15, 50], bracket_position: "Bracket Round of 64", round: 1 },
          { seeds: [18, 47], bracket_position: "Bracket Round of 64", round: 1 },
          { seeds: [31, 34], bracket_position: "Bracket Round of 64", round: 1 },
          { seeds: [2, 63], bracket_position: "Bracket Round of 64", round: 1 }
        ],
        championship_rounds: [
          { bracket_position: "Bracket Round of 32", number_of_matches: 16, round: 2 },
          { bracket_position: "Bracket Round of 16", number_of_matches: 8, round: 3 },
          { bracket_position: "Quarter", number_of_matches: 4, round: 4 },
          { bracket_position: "Semis", number_of_matches: 2, round: 5 },
          { bracket_position: "1/2", number_of_matches: 1, round: 10 }
        ],
        consolation_rounds: [
          { bracket_position: "Conso Round of 32.1", number_of_matches: 16, round: 2 },
          { bracket_position: "Conso Round of 32.2", number_of_matches: 16, round: 3 },
          { bracket_position: "Conso Round of 16.1", number_of_matches: 8, round: 4 },
          { bracket_position: "Conso Round of 16.2", number_of_matches: 8, round: 5 },
          { bracket_position: "Conso Round of 8.1", number_of_matches: 4, round: 6 },
          { bracket_position: "Conso Round of 8.2", number_of_matches: 4, round: 7 },
          { bracket_position: "Conso Quarter", number_of_matches: 2, round: 8 },
          { bracket_position: "Conso Semis", number_of_matches: 2, round: 9 },
          { bracket_position: "3/4", number_of_matches: 1, round: 10 }
        ]
      }
    else
      nil
    end
  end

  ###########################################################################
  # PHASE 2: Overwrite rounds in all smaller brackets to match the largest one.
  ###########################################################################
  def align_all_rounds_to_largest_bracket
    #
    # 1) Find the bracket size that is largest
    #
    largest_weight = @tournament.weights.max_by { |w| w.calculate_bracket_size }
    return unless largest_weight

    #
    # 2) Gather all matches for that bracket. Build a map from bracket_position => round
    #
    #    We assume "largest bracket" is the single weight with the largest bracket_size.
    #
    largest_bracket_size = largest_weight.calculate_bracket_size
    largest_matches = largest_weight.tournament.matches.where(weight_id: largest_weight.id)

    position_to_round = {}
    largest_matches.each do |m|
      # In case multiple matches have the same bracket_position but different rounds
      # (like "3/4" might appear more than once), you can pick the first or max. 
      position_to_round[m.bracket_position] ||= m.round  
    end

    #
    # 3) For every other match in the entire tournament (including possibly the largest bracket, if you want),
    #    overwrite the round to match this map.
    #
    @tournament.matches.find_each do |match|
      # If there's a known round for this bracket_position, use it
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
end
