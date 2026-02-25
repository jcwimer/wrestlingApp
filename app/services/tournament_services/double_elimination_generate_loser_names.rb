class DoubleEliminationGenerateLoserNames
  def initialize(tournament)
    @tournament = tournament
  end

  # Compatibility wrapper. Returns transformed rows and does not persist.
  def assign_loser_names(match_rows = nil)
    rows = match_rows || @tournament.matches.where(tournament_id: @tournament.id).map { |m| m.attributes.symbolize_keys }
    @tournament.weights.each do |weight|
      next unless weight.calculate_bracket_size > 2

      assign_loser_names_in_memory(weight, rows)
      assign_bye_outcomes_in_memory(weight, rows)
    end
    rows
  end

  def assign_loser_names_in_memory(weight, match_rows)
    bracket_size = weight.calculate_bracket_size
    return if bracket_size <= 2

    rows = match_rows.select { |row| row[:weight_id] == weight.id }
    num_placers = @tournament.number_of_placers

    champ_rounds = dynamic_championship_rounds(bracket_size)
    conso_rounds = dynamic_consolation_rounds(bracket_size)
    first_round = { bracket_position: first_round_label(bracket_size) }
    champ_full = [first_round] + champ_rounds

    mappings = []
    champ_full[0...-1].each_with_index do |champ_info, i|
      map_idx = i.zero? ? 0 : (2 * i - 1)
      next if map_idx < 0 || map_idx >= conso_rounds.size

      mappings << {
        championship_bracket_position: champ_info[:bracket_position],
        consolation_bracket_position: conso_rounds[map_idx][:bracket_position],
        both_wrestlers: i.zero?,
        champ_round_index: i
      }
    end

    mappings.each do |map|
      champ = rows.select { |r| r[:bracket_position] == map[:championship_bracket_position] }
                  .sort_by { |r| r[:bracket_position_number] }
      conso = rows.select { |r| r[:bracket_position] == map[:consolation_bracket_position] }
                  .sort_by { |r| r[:bracket_position_number] }
      conso.reverse! if map[:champ_round_index].odd?

      idx = 0
      is_first_feed = map[:champ_round_index].zero?
      conso.each do |cm|
        champ_match1 = champ[idx]
        if champ_match1
          if is_first_feed && single_competitor_match_row?(champ_match1)
            cm[:loser1_name] = "BYE"
          else
            cm[:loser1_name] = "Loser of #{champ_match1[:bout_number]}"
          end
        else
          cm[:loser1_name] = nil
        end

        if map[:both_wrestlers]
          idx += 1
          champ_match2 = champ[idx]
          if champ_match2
            if is_first_feed && single_competitor_match_row?(champ_match2)
              cm[:loser2_name] = "BYE"
            else
              cm[:loser2_name] = "Loser of #{champ_match2[:bout_number]}"
            end
          else
            cm[:loser2_name] = nil
          end
        end
        idx += 1
      end
    end

    if bracket_size >= 5 && num_placers >= 6 && weight.wrestlers.size > 4
      conso_semis = rows.select { |r| r[:bracket_position] == "Conso Semis" }.sort_by { |r| r[:bracket_position_number] }
      m56 = rows.find { |r| r[:bracket_position] == "5/6" }
      if conso_semis.size >= 2 && m56
        m56[:loser1_name] = "Loser of #{conso_semis[0][:bout_number]}"
        m56[:loser2_name] = "Loser of #{conso_semis[1][:bout_number]}"
      end
    end

    if bracket_size >= 7 && num_placers >= 8 && weight.wrestlers.size > 6
      conso_quarters = rows.select { |r| r[:bracket_position] == "Conso Quarter" }.sort_by { |r| r[:bracket_position_number] }
      m78 = rows.find { |r| r[:bracket_position] == "7/8" }
      if conso_quarters.size >= 2 && m78
        m78[:loser1_name] = "Loser of #{conso_quarters[0][:bout_number]}"
        m78[:loser2_name] = "Loser of #{conso_quarters[1][:bout_number]}"
      end
    end
  end

  def assign_bye_outcomes_in_memory(weight, match_rows)
    bracket_size = weight.calculate_bracket_size
    return if bracket_size <= 2

    rows = match_rows.select { |r| r[:weight_id] == weight.id }
    first_round = rows.map { |r| r[:round] }.compact.min
    rows.select { |r| r[:round] == first_round }.each { |row| apply_bye_to_row(row) }

    first_conso = dynamic_consolation_rounds(bracket_size).first
    if first_conso
      rows.select { |r| r[:round] == first_conso[:round] && r[:bracket_position] == first_conso[:bracket_position] }
          .each { |row| apply_bye_to_row(row) }
    end
  end

  def apply_bye_to_row(row)
    return unless single_competitor_match_row?(row)

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

  def single_competitor_match_row?(row)
    [row[:w1], row[:w2]].compact.size == 1
  end

  def first_round_label(size)
    case size
    when 2 then "Final"
    when 4 then "Semis"
    when 8 then "Quarter"
    else "Bracket Round of #{size}"
    end
  end

  def dynamic_championship_rounds(size)
    total = Math.log2(size).to_i
    (1...total).map do |i|
      participants = size / (2**i)
      { bracket_position: bracket_label(participants), round: i + 1 }
    end
  end

  def dynamic_consolation_rounds(size)
    total_log2 = Math.log2(size).to_i
    return [] if total_log2 <= 1

    max_j_val = (2 * (total_log2 - 1) - 1)
    (1..max_j_val).map do |j|
      current_participants = size / (2**((j.to_f / 2).ceil))
      {
        bracket_position: consolation_label(current_participants, j, size),
        round: j
      }
    end
  end

  def bracket_label(participants)
    case participants
    when 2 then "1/2"
    when 4 then "Semis"
    when 8 then "Quarter"
    else "Bracket Round of #{participants}"
    end
  end

  def consolation_label(participants, j, bracket_size)
    max_j_for_bracket = (2 * (Math.log2(bracket_size).to_i - 1) - 1)

    if participants == 2 && j == max_j_for_bracket
      "3/4"
    elsif participants == 4
      j.odd? ? "Conso Quarter" : "Conso Semis"
    else
      suffix = j.odd? ? ".1" : ".2"
      "Conso Round of #{participants}#{suffix}"
    end
  end
end
