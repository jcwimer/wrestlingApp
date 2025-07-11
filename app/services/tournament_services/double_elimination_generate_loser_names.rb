class DoubleEliminationGenerateLoserNames
  def initialize(tournament)
    @tournament = tournament
  end

  # Entry point: assign loser placeholders and advance any byes
  def assign_loser_names
    @tournament.weights.each do |weight|
      assign_loser_names_for_weight(weight)
      advance_bye_matches_championship(weight)
      advance_bye_matches_consolation(weight)
    end
  end

  private

  # Assign loser names for a single weight bracket
  def assign_loser_names_for_weight(weight)
    bracket_size = weight.calculate_bracket_size
    matches      = weight.matches.reload
    num_placers  = @tournament.number_of_placers

    # Build dynamic round definitions
    champ_rounds = dynamic_championship_rounds(bracket_size)
    conso_rounds = dynamic_consolation_rounds(bracket_size)
    first_round  = { bracket_position: first_round_label(bracket_size) }
    champ_full   = [first_round] + champ_rounds

    # Map championship losers into consolation slots
    mappings = []
    champ_full[0...-1].each_with_index do |champ_info, i|
      map_idx = i.zero? ? 0 : (2 * i - 1)
      next if map_idx < 0 || map_idx >= conso_rounds.size

      mappings << {
        championship_bracket_position: champ_info[:bracket_position],
        consolation_bracket_position:  conso_rounds[map_idx][:bracket_position],
        both_wrestlers:               i.zero?,
        champ_round_index:            i
      }
    end

    # Apply loser-name mappings
    mappings.each do |map|
      champ = matches.select { |m| m.bracket_position == map[:championship_bracket_position] }
                     .sort_by(&:bracket_position_number)
      conso = matches.select { |m| m.bracket_position == map[:consolation_bracket_position] }
                     .sort_by(&:bracket_position_number)
      
      current_champ_round_index = map[:champ_round_index]
      if current_champ_round_index.odd?
        conso.reverse!
      end

      idx = 0
      # Determine if this mapping is for losers from the first championship round
      is_first_champ_round_feed = map[:champ_round_index].zero?

      conso.each do |cm|
        champ_match1 = champ[idx]
        if champ_match1
          if is_first_champ_round_feed && ((champ_match1.w1 && champ_match1.w2.nil?) || (champ_match1.w1.nil? && champ_match1.w2))
            cm.loser1_name = "BYE"
          else
            cm.loser1_name = "Loser of #{champ_match1.bout_number}"
          end
        else
          cm.loser1_name = nil # Should not happen if bracket generation is correct
        end

        if map[:both_wrestlers] # This is true only if is_first_champ_round_feed
          idx += 1 # Increment for the second championship match
          champ_match2 = champ[idx]
          if champ_match2
            # BYE check is only relevant for the first championship round feed
            if is_first_champ_round_feed && ((champ_match2.w1 && champ_match2.w2.nil?) || (champ_match2.w1.nil? && champ_match2.w2))
              cm.loser2_name = "BYE"
            else
              cm.loser2_name = "Loser of #{champ_match2.bout_number}"
            end
          else
            cm.loser2_name = nil # Should not happen
          end
        end
        idx += 1 # Increment for the next consolation match or next pair from championship
      end
    end

    # 5th/6th place
    if bracket_size >= 5 && num_placers >= 6
      conso_semis = matches.select { |m| m.bracket_position == "Conso Semis" }
                           .sort_by(&:bracket_position_number)
      if conso_semis.size >= 2
        m56 = matches.find { |m| m.bracket_position == "5/6" }
        m56.loser1_name = "Loser of #{conso_semis[0].bout_number}"
        m56.loser2_name = "Loser of #{conso_semis[1].bout_number}" if m56
      end
    end

    # 7th/8th place
    if bracket_size >= 7 && num_placers >= 8
      conso_quarters = matches.select { |m| m.bracket_position == "Conso Quarter" }
                                .sort_by(&:bracket_position_number)
      if conso_quarters.size >= 2
        m78 = matches.find { |m| m.bracket_position == "7/8" }
        m78.loser1_name = "Loser of #{conso_quarters[0].bout_number}"
        m78.loser2_name = "Loser of #{conso_quarters[1].bout_number}" if m78
      end
    end

    matches.each(&:save!)
  end

  # Advance first-round byes in championship bracket
  def advance_bye_matches_championship(weight)
    matches    = weight.matches.reload
    first_round = matches.map(&:round).min
    matches.select { |m| m.round == first_round }
           .sort_by(&:bracket_position_number)
           .each { |m| handle_bye(m) }
  end

  # Advance first-round byes in consolation bracket
  def advance_bye_matches_consolation(weight)
    matches      = weight.matches.reload
    bracket_size = weight.calculate_bracket_size
    first_conso  = dynamic_consolation_rounds(bracket_size).first

    matches.select { |m| m.round == first_conso[:round] && m.bracket_position == first_conso[:bracket_position] }
           .sort_by(&:bracket_position_number)
           .each { |m| handle_bye(m) }
  end

  # Mark bye match, set finished, and advance
  def handle_bye(match)
    if [match.w1, match.w2].compact.size == 1
      match.finished = 1
      match.win_type  = 'BYE'
      if match.w1
        match.winner_id   = match.w1
        match.loser2_name = 'BYE'
      else
        match.winner_id   = match.w2
        match.loser1_name = 'BYE'
      end
      match.score = ''
      match.save!
      match.advance_wrestlers
    end
  end

  # Helpers for dynamic bracket labels
  def first_round_label(size)
    case size
    when 2  then 'Final'
    when 4  then 'Semis'
    when 8  then 'Quarter'
    else      "Bracket Round of #{size}" 
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
    when 2 then '1/2'
    when 4 then 'Semis'
    when 8 then 'Quarter'
    else       "Bracket Round of #{participants}"
    end
  end

  def consolation_label(participants, j, bracket_size)
    max_j_for_bracket = (2 * (Math.log2(bracket_size).to_i - 1) - 1)
    
    if participants == 2 && j == max_j_for_bracket
      return '3/4'
    elsif participants == 4
      return j.odd? ? 'Conso Quarter' : 'Conso Semis'
    else
      suffix = j.odd? ? ".1" : ".2"
      return "Conso Round of #{participants}#{suffix}"
    end
  end
end