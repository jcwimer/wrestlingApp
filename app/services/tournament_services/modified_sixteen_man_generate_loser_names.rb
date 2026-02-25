class ModifiedSixteenManGenerateLoserNames
  def initialize(tournament)
    @tournament = tournament
  end

  # Compatibility wrapper. Returns transformed rows and does not persist.
  def assign_loser_names(match_rows = nil)
    rows = match_rows || @tournament.matches.where(tournament_id: @tournament.id).map { |m| m.attributes.symbolize_keys }
    @tournament.weights.each do |weight|
      assign_loser_names_in_memory(weight, rows)
      assign_bye_outcomes_in_memory(weight, rows)
    end
    rows
  end

  def assign_loser_names_in_memory(weight, match_rows)
    rows = match_rows.select { |row| row[:weight_id] == weight.id }
    round_16 = rows.select { |r| r[:bracket_position] == "Bracket Round of 16" }
    conso_8 = rows.select { |r| r[:bracket_position] == "Conso Round of 8" }.sort_by { |r| r[:bracket_position_number] }

    conso_8.each do |row|
      if row[:bracket_position_number] == 1
        m1 = round_16.find { |m| m[:bracket_position_number] == 1 }
        m2 = round_16.find { |m| m[:bracket_position_number] == 2 }
        row[:loser1_name] = "Loser of #{m1[:bout_number]}" if m1
        row[:loser2_name] = "Loser of #{m2[:bout_number]}" if m2
      elsif row[:bracket_position_number] == 2
        m3 = round_16.find { |m| m[:bracket_position_number] == 3 }
        m4 = round_16.find { |m| m[:bracket_position_number] == 4 }
        row[:loser1_name] = "Loser of #{m3[:bout_number]}" if m3
        row[:loser2_name] = "Loser of #{m4[:bout_number]}" if m4
      elsif row[:bracket_position_number] == 3
        m5 = round_16.find { |m| m[:bracket_position_number] == 5 }
        m6 = round_16.find { |m| m[:bracket_position_number] == 6 }
        row[:loser1_name] = "Loser of #{m5[:bout_number]}" if m5
        row[:loser2_name] = "Loser of #{m6[:bout_number]}" if m6
      elsif row[:bracket_position_number] == 4
        m7 = round_16.find { |m| m[:bracket_position_number] == 7 }
        m8 = round_16.find { |m| m[:bracket_position_number] == 8 }
        row[:loser1_name] = "Loser of #{m7[:bout_number]}" if m7
        row[:loser2_name] = "Loser of #{m8[:bout_number]}" if m8
      end
    end

    quarters = rows.select { |r| r[:bracket_position] == "Quarter" }
    conso_quarters = rows.select { |r| r[:bracket_position] == "Conso Quarter" }.sort_by { |r| r[:bracket_position_number] }
    conso_quarters.each do |row|
      source = case row[:bracket_position_number]
               when 1 then quarters.find { |q| q[:bracket_position_number] == 4 }
               when 2 then quarters.find { |q| q[:bracket_position_number] == 3 }
               when 3 then quarters.find { |q| q[:bracket_position_number] == 2 }
               when 4 then quarters.find { |q| q[:bracket_position_number] == 1 }
               end
      row[:loser1_name] = "Loser of #{source[:bout_number]}" if source
    end

    semis = rows.select { |r| r[:bracket_position] == "Semis" }
    third_fourth = rows.find { |r| r[:bracket_position] == "3/4" }
    if third_fourth
      third_fourth[:loser1_name] = "Loser of #{semis.first[:bout_number]}" if semis.first
      third_fourth[:loser2_name] = "Loser of #{semis.second[:bout_number]}" if semis.second
    end

    conso_semis = rows.select { |r| r[:bracket_position] == "Conso Semis" }
    seventh_eighth = rows.find { |r| r[:bracket_position] == "7/8" }
    if seventh_eighth
      seventh_eighth[:loser1_name] = "Loser of #{conso_semis.first[:bout_number]}" if conso_semis.first
      seventh_eighth[:loser2_name] = "Loser of #{conso_semis.second[:bout_number]}" if conso_semis.second
    end
  end

  def assign_bye_outcomes_in_memory(weight, match_rows)
    rows = match_rows.select { |r| r[:weight_id] == weight.id && r[:bracket_position] == "Bracket Round of 16" }
    rows.each { |row| apply_bye_to_row(row) }
  end

  def apply_bye_to_row(row)
    return unless [row[:w1], row[:w2]].compact.size == 1

    row[:finished] = 1
    row[:win_type] = "BYE"
    if row[:w1]
      row[:winner_id] = row[:w1]
      row[:loser2_name] = "BYE"
    else
      row[:winner_id] = row[:w2]
      row[:loser1_name] = "BYE"
    end
    row[:score] = ""
  end
end
