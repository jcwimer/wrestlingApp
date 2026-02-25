class PoolToBracketGenerateLoserNames
  def initialize(tournament)
    @tournament = tournament
  end

  # Compatibility wrapper. Returns transformed rows and does not persist.
  def assignLoserNamesWeight(weight, match_rows = nil)
    rows = match_rows || @tournament.matches.where(weight_id: weight.id).map { |m| m.attributes.symbolize_keys }
    assign_loser_names_in_memory(weight, rows)
    rows
  end

  # Compatibility wrapper. Returns transformed rows and does not persist.
  def assignLoserNames
    @tournament.weights.each_with_object([]) do |weight, all_rows|
      all_rows.concat(assignLoserNamesWeight(weight))
    end
  end

  def assign_loser_names_in_memory(weight, match_rows)
    rows = match_rows.select { |row| row[:weight_id] == weight.id }
    if weight.pool_bracket_type == "twoPoolsToSemi"
      two_pools_to_semi_loser_rows(rows)
    elsif (weight.pool_bracket_type == "fourPoolsToQuarter") || (weight.pool_bracket_type == "eightPoolsToQuarter")
      four_pools_to_quarter_loser_rows(rows)
    elsif weight.pool_bracket_type == "fourPoolsToSemi"
      four_pools_to_semi_loser_rows(rows)
    end
  end

  def two_pools_to_semi_loser_rows(rows)
    match1 = rows.find { |m| m[:loser1_name] == "Winner Pool 1" }
    match2 = rows.find { |m| m[:loser1_name] == "Winner Pool 2" }
    match_change = rows.find { |m| m[:bracket_position] == "3/4" }
    return unless match1 && match2 && match_change

    match_change[:loser1_name] = "Loser of #{match1[:bout_number]}"
    match_change[:loser2_name] = "Loser of #{match2[:bout_number]}"
  end

  def four_pools_to_quarter_loser_rows(rows)
    quarters = rows.select { |m| m[:bracket_position] == "Quarter" }
    conso_semis = rows.select { |m| m[:bracket_position] == "Conso Semis" }
    semis = rows.select { |m| m[:bracket_position] == "Semis" }
    third_fourth = rows.find { |m| m[:bracket_position] == "3/4" }
    seventh_eighth = rows.find { |m| m[:bracket_position] == "7/8" }

    conso_semis.each do |m|
      if m[:bracket_position_number] == 1
        q1 = quarters.find { |q| q[:bracket_position_number] == 1 }
        q2 = quarters.find { |q| q[:bracket_position_number] == 2 }
        m[:loser1_name] = "Loser of #{q1[:bout_number]}" if q1
        m[:loser2_name] = "Loser of #{q2[:bout_number]}" if q2
      elsif m[:bracket_position_number] == 2
        q3 = quarters.find { |q| q[:bracket_position_number] == 3 }
        q4 = quarters.find { |q| q[:bracket_position_number] == 4 }
        m[:loser1_name] = "Loser of #{q3[:bout_number]}" if q3
        m[:loser2_name] = "Loser of #{q4[:bout_number]}" if q4
      end
    end

    if third_fourth
      s1 = semis.find { |s| s[:bracket_position_number] == 1 }
      s2 = semis.find { |s| s[:bracket_position_number] == 2 }
      third_fourth[:loser1_name] = "Loser of #{s1[:bout_number]}" if s1
      third_fourth[:loser2_name] = "Loser of #{s2[:bout_number]}" if s2
    end

    if seventh_eighth
      c1 = conso_semis.find { |c| c[:bracket_position_number] == 1 }
      c2 = conso_semis.find { |c| c[:bracket_position_number] == 2 }
      seventh_eighth[:loser1_name] = "Loser of #{c1[:bout_number]}" if c1
      seventh_eighth[:loser2_name] = "Loser of #{c2[:bout_number]}" if c2
    end
  end

  def four_pools_to_semi_loser_rows(rows)
    semis = rows.select { |m| m[:bracket_position] == "Semis" }
    conso_semis = rows.select { |m| m[:bracket_position] == "Conso Semis" }
    third_fourth = rows.find { |m| m[:bracket_position] == "3/4" }
    seventh_eighth = rows.find { |m| m[:bracket_position] == "7/8" }

    if third_fourth
      s1 = semis.find { |s| s[:bracket_position_number] == 1 }
      s2 = semis.find { |s| s[:bracket_position_number] == 2 }
      third_fourth[:loser1_name] = "Loser of #{s1[:bout_number]}" if s1
      third_fourth[:loser2_name] = "Loser of #{s2[:bout_number]}" if s2
    end

    if seventh_eighth
      c1 = conso_semis.find { |c| c[:bracket_position_number] == 1 }
      c2 = conso_semis.find { |c| c[:bracket_position_number] == 2 }
      seventh_eighth[:loser1_name] = "Loser of #{c1[:bout_number]}" if c1
      seventh_eighth[:loser2_name] = "Loser of #{c2[:bout_number]}" if c2
    end
  end
end
