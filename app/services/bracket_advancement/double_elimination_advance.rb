class DoubleEliminationAdvance

 attr_reader :matches_to_advance

 def initialize(wrestler,last_match, matches: nil)
		@wrestler = wrestler
		@last_match = last_match
    @matches = matches || @wrestler.weight.matches.to_a
    @matches_to_advance = []
    @next_match_position_number = (@last_match.bracket_position_number / 2.0)
 end

 def bracket_advancement
   advance_wrestler
   advance_double_byes
   set_bye_for_placement
 end

 def advance_wrestler
		# Advance winner
		if @last_match.winner == @wrestler
			winners_bracket_advancement
		# Advance loser
		elsif @last_match.winner != @wrestler
			losers_bracket_advancement
		end
	end

 def winners_bracket_advancement
  if (@last_match.loser1_name == "BYE" or @last_match.loser2_name == "BYE") and @last_match.is_championship_match
    update_consolation_bye
  end

  future_round_matches = @last_match.weight.matches.select{|m| m.round > @last_match.round}
  next_match = nil
  next_match_bracket_position = nil
  next_match_position_number = @next_match_position_number.ceil

  if @last_match.is_championship_match and future_round_matches.size > 0
    next_match_round = future_round_matches.select{|m| m.is_championship_match}.sort_by{|m| m.round}.first.round
    next_match_bracket_position = future_round_matches.select{|m| m.is_championship_match}.sort_by{|m| m.round}.first.bracket_position
  end

  if @last_match.is_consolation_match and future_round_matches.size > 0
    next_match_round = future_round_matches.select{|m| m.is_consolation_match}.sort_by{|m| m.round}.first.round
    next_match_bracket_position = future_round_matches.select{|m| m.is_consolation_match}.sort_by{|m| m.round}.first.bracket_position
    next_match_loser1_name = future_round_matches.select{|m| m.is_consolation_match}.sort_by{|m| m.round}.first.loser1_name
    # If someone is falling down to them in this round, then their bracket_position_number stays the same
    if next_match_loser1_name
      next_match_position_number = @last_match.bracket_position_number
    end
  end

  if next_match_bracket_position
    next_match = @matches.find { |m| m.bracket_position == next_match_bracket_position && m.bracket_position_number == next_match_position_number.ceil && m.weight_id == @wrestler.weight_id }
  end

  if next_match
    update_new_match(next_match, get_wrestler_number)
  end
 end
 
 def update_new_match(match, wrestler_number)
     if wrestler_number == 2 or (match.loser1_name and match.loser1_name.include? "Loser of")
	      match.w2 = @wrestler.id
     elsif  wrestler_number == 1
	      match.w1 = @wrestler.id
     end
 end

 def update_consolation_bye
    bout = @wrestler.last_match.bout_number
    next_match = @matches.find { |m| m.weight_id == @wrestler.weight_id && (m.loser1_name == "Loser of #{bout}" || m.loser2_name == "Loser of #{bout}") }
    if next_match
      replace_loser_name_with_bye(next_match, "Loser of #{bout}")
    end
 end

 def get_wrestler_number
   if @next_match_position_number != @next_match_position_number.ceil
      return 1
   elsif @next_match_position_number == @next_match_position_number.ceil
      return 2
   end
 end

 def losers_bracket_advancement
  bout = @last_match.bout_number
  next_match = @matches.find { |m| m.weight_id == @wrestler.weight_id && (m.loser1_name == "Loser of #{bout}" || m.loser2_name == "Loser of #{bout}") }
  
  if next_match.present?
    replace_loser_name_with_wrestler(next_match, @wrestler, "Loser of #{bout}")

    if next_match.loser1_name == "BYE" || next_match.loser2_name == "BYE"
      next_match.winner_id = @wrestler.id
      next_match.win_type = "BYE"
      next_match.score = ""
      next_match.finished = 1
      next_match.finished_at = Time.current
      @matches_to_advance << next_match
    end
  end
 end


 def advance_double_byes
   weight = @wrestler.weight
   @matches.select{|m| m.weight_id == weight.id && m.loser1_name == "BYE" and m.loser2_name == "BYE" and m.finished != 1}.each do |match|
      match.finished = 1
      match.finished_at = Time.current
      match.score = ""
      match.win_type = "BYE"
      next_match_position_number = (match.bracket_position_number / 2.0).ceil
      after_matches = @matches.select{|m| m.weight_id == weight.id && m.round > match.round and m.is_consolation_match == match.is_consolation_match }.sort_by{|m| m.round}
      next if after_matches.empty?
      next_matches = @matches.select{|m| m.weight_id == weight.id && m.round == after_matches.first.round and m.is_consolation_match == match.is_consolation_match }
      this_round_matches = @matches.select{|m| m.weight_id == weight.id && m.round == match.round and m.is_consolation_match == match.is_consolation_match }
      next_match = nil

      if next_matches.size == this_round_matches.size
        next_match = next_matches.select{|m| m.bracket_position_number == match.bracket_position_number}.first
        next_match.loser2_name = "BYE" if next_match
      elsif next_matches.size < this_round_matches.size and next_matches.size > 0
        next_match = next_matches.select{|m| m.bracket_position_number == next_match_position_number}.first
        if next_match && next_match.bracket_position_number == next_match_position_number
          next_match.loser2_name = "BYE"
        elsif next_match
          next_match.loser1_name = "BYE"
        end
      end
   end
 end

 def set_bye_for_placement
  weight = @wrestler.weight
  fifth_finals = @matches.select{|match| match.weight_id == weight.id && match.bracket_position == '5/6'}.first
  seventh_finals = @matches.select{|match| match.weight_id == weight.id && match.bracket_position == '7/8'}.first
  if seventh_finals
    conso_quarter = @matches.select{|match| match.weight_id == weight.id && match.bracket_position == 'Conso Quarter'}
    conso_quarter.each do |match|
      if match.loser1_name == "BYE" or match.loser2_name == "BYE"
        replace_loser_name_with_bye(seventh_finals, "Loser of #{match.bout_number}")
      end
    end
  end
  if fifth_finals
    conso_semis = @matches.select{|match| match.weight_id == weight.id && match.bracket_position == 'Conso Semis'}
    conso_semis.each do |match|
      if match.loser1_name == "BYE" or match.loser2_name == "BYE"
        replace_loser_name_with_bye(fifth_finals, "Loser of #{match.bout_number}")
      end
    end
  end
 end

 def replace_loser_name_with_wrestler(match, wrestler, loser_name)
   if match.loser1_name == loser_name
     match.w1 = wrestler.id
   end
   if match.loser2_name == loser_name
     match.w2 = wrestler.id
   end
 end

 def replace_loser_name_with_bye(match, loser_name)
   if match.loser1_name == loser_name
     match.loser1_name = "BYE"
   end
   if match.loser2_name == loser_name
     match.loser2_name = "BYE"
   end
 end
end
