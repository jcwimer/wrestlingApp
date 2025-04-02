class DoubleEliminationGenerateLoserNames
  def initialize(tournament)
    @tournament = tournament
  end

  def assign_loser_names
    @tournament.weights.each do |weight|
      assign_loser_names_for_weight(weight)
      advance_bye_matches_championship(weight.matches.reload)
    end
  end

  def define_losername_championship_mappings(bracket_size)
    # Use hashes instead of arrays for mappings
    case bracket_size
    when 4
      [
        { conso_bracket_position: "3/4", championship_bracket_position: "Semis", cross_bracket: false, both_wrestlers: true }
      ]
    when 8
      [
        { conso_bracket_position: "Conso Quarter", championship_bracket_position: "Quarter", cross_bracket: false, both_wrestlers: true },
        { conso_bracket_position: "Conso Semis", championship_bracket_position: "Semis", cross_bracket: true, both_wrestlers: false }
      ]
    when 16
      [
        { conso_bracket_position: "Conso Round of 8.1", championship_bracket_position: "Bracket Round of 16", cross_bracket: false, both_wrestlers: true },
        { conso_bracket_position: "Conso Round of 8.2", championship_bracket_position: "Quarter", cross_bracket: true, both_wrestlers: false },
        { conso_bracket_position: "Conso Semis", championship_bracket_position: "Semis", cross_bracket: false, both_wrestlers: false }
      ]
    when 32
      [
        { conso_bracket_position: "Conso Round of 16.1", championship_bracket_position: "Bracket Round of 32", cross_bracket: false, both_wrestlers: true },
        { conso_bracket_position: "Conso Round of 16.2", championship_bracket_position: "Bracket Round of 16", cross_bracket: true, both_wrestlers: false },
        { conso_bracket_position: "Conso Round of 8.2", championship_bracket_position: "Quarter", cross_bracket: false, both_wrestlers: false },
        { conso_bracket_position: "Conso Semis", championship_bracket_position: "Semis", cross_bracket: true, both_wrestlers: false },

      ]
    else
      nil
    end
  end

  def assign_loser_names_for_weight(weight)
    number_of_placers = @tournament.number_of_placers
    bracket_size = weight.calculate_bracket_size
    matches_by_weight = weight.matches.reload

    loser_name_championship_mappings = define_losername_championship_mappings(bracket_size)

    loser_name_championship_mappings.each do |mapping|
      conso_bracket_position = mapping[:conso_bracket_position]
      championship_bracket_position = mapping[:championship_bracket_position]
      cross_bracket = mapping[:cross_bracket]
      both_wrestlers = mapping[:both_wrestlers]

      conso_matches = matches_by_weight.select do |match|
        match.bracket_position == conso_bracket_position && match.bracket_position == conso_bracket_position
      end.sort_by(&:bracket_position_number)

      championship_matches = matches_by_weight.select do |match|
        match.bracket_position == championship_bracket_position && match.bracket_position == championship_bracket_position
      end.sort_by(&:bracket_position_number)

      conso_matches.reverse! if cross_bracket

      championship_bracket_position_number = 1
      conso_matches.each do |match|
        bout_number1 = championship_matches.find do |bout_match|
          bout_match.bracket_position_number == championship_bracket_position_number
        end.bout_number

        match.loser1_name = "Loser of #{bout_number1}"
        if both_wrestlers
          championship_bracket_position_number += 1
          bout_number2 = championship_matches.find do |bout_match|
            bout_match.bracket_position_number == championship_bracket_position_number
          end.bout_number
          match.loser2_name = "Loser of #{bout_number2}"
        end
        championship_bracket_position_number += 1
      end
    end

    conso_semi_matches = matches_by_weight.select { |match| match.bracket_position == "Conso Semis" }
    conso_quarter_matches = matches_by_weight.select { |match| match.bracket_position == "Conso Quarter" }

    if number_of_placers >= 6 && weight.wrestlers.size >= 5
      five_six_match = matches_by_weight.find { |match| match.bracket_position == "5/6" }
      bout_number1 = conso_semi_matches.find { |match| match.bracket_position_number == 1 }.bout_number
      bout_number2 = conso_semi_matches.find { |match| match.bracket_position_number == 2 }.bout_number
      five_six_match.loser1_name = "Loser of #{bout_number1}"
      five_six_match.loser2_name = "Loser of #{bout_number2}"
    end

    if number_of_placers >= 8 && weight.wrestlers.size >= 7
      seven_eight_match = matches_by_weight.find { |match| match.bracket_position == "7/8" }
      bout_number1 = conso_quarter_matches.find { |match| match.bracket_position_number == 1 }.bout_number
      bout_number2 = conso_quarter_matches.find { |match| match.bracket_position_number == 2 }.bout_number
      seven_eight_match.loser1_name = "Loser of #{bout_number1}"
      seven_eight_match.loser2_name = "Loser of #{bout_number2}"
    end

    save_matches(matches_by_weight)
  end

  def save_matches(matches)
    matches.each(&:save!)
  end

  def advance_bye_matches_championship(matches)
    first_round = matches.sort_by{|m| m.round}.first.round
    matches.select do |m|
      m.round == first_round
    end.sort_by(&:bracket_position_number).each do |match|
      next unless match.w1.nil? || match.w2.nil?

      match.finished = 1
      match.win_type = "BYE"
      if match.w1
        match.winner_id = match.w1
        match.loser2_name = "BYE"
      elsif match.w2
        match.winner_id = match.w2
        match.loser1_name = "BYE"
      end
      match.score = ""
      match.save
      match.advance_wrestlers
    end
  end
end
