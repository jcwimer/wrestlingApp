class DoubleEliminationAdvance

 def initialize(wrestler,last_match)
		@wrestler = wrestler
		@last_match = last_match
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
    next_match = Match.where("bracket_position = ? AND bracket_position_number = ? AND weight_id = ?",next_match_bracket_position,next_match_position_number.ceil,@wrestler.weight_id).first
  end

  if next_match
    update_new_match(next_match, get_wrestler_number)
  end
 end
 
 def update_new_match(match, wrestler_number)
     if wrestler_number == 2 or (match.loser1_name and match.loser1_name.include? "Loser of")
	      match.w2 = @wrestler.id
      	match.save
     elsif  wrestler_number == 1
	      match.w1 = @wrestler.id
	      match.save
     end
 end

 def update_consolation_bye
    bout = @wrestler.last_match.bout_number
    next_match = Match.where("(loser1_name = ? OR loser2_name = ?) AND weight_id = ?","Loser of #{bout}","Loser of #{bout}",@wrestler.weight_id)
    if next_match.size > 0
      next_match.first.replace_loser_name_with_bye("Loser of #{bout}")
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
  next_match = Match.where("(loser1_name = ? OR loser2_name = ?) AND weight_id = ?", "Loser of #{bout}", "Loser of #{bout}", @wrestler.weight_id).first
  
  if next_match.present?
    next_match.replace_loser_name_with_wrestler(@wrestler, "Loser of #{bout}")
    next_match.reload

    if next_match.loser1_name == "BYE" || next_match.loser2_name == "BYE"
      next_match.winner_id = @wrestler.id
      next_match.win_type = "BYE"
      next_match.score = ""
      next_match.finished = 1
      # puts "Before save: winner_id=#{next_match.winner_id}"
      
      # if next_match.save
      #   puts "Save successful: winner_id=#{next_match.reload.winner_id}"
      # else
      #   puts "Save failed: #{next_match.errors.full_messages}"
      # end
      next_match.save

      next_match.advance_wrestlers
    end
  end
 end


 def advance_double_byes
   weight = @wrestler.weight
   weight.matches.select{|m| m.loser1_name == "BYE" and m.loser2_name == "BYE" and m.finished != 1}.each do |match|
      match.finished = 1
      match.score = ""
      match.win_type = "BYE"
      next_match_position_number = (match.bracket_position_number / 2.0).ceil
      after_matches = weight.matches.select{|m| m.round > match.round and m.is_consolation_match == match.is_consolation_match }.sort_by{|m| m.round}
      next_matches = weight.matches.select{|m| m.round == after_matches.first.round and m.is_consolation_match == match.is_consolation_match }
      this_round_matches = weight.matches.select{|m| m.round == match.round and m.is_consolation_match == match.is_consolation_match }

      if next_matches.size == this_round_matches.size
        next_match = next_matches.select{|m| m.bracket_position_number == match.bracket_position_number}.first
        next_match.loser2_name = "BYE"
        next_match.save
      elsif next_matches.size < this_round_matches.size and next_matches.size > 0
        next_match = next_matches.select{|m| m.bracket_position_number == next_match_position_number}.first
        if next_match.bracket_position_number == next_match_position_number
          next_match.loser2_name = "BYE"
        else
          next_match.loser1_name = "BYE"
        end
      end
      next_match.save
      match.save
   end
 end

 def set_bye_for_placement
  weight = @wrestler.weight
  fifth_finals = weight.matches.select{|match| match.bracket_position == '5/6'}.first
  seventh_finals = weight.matches.select{|match| match.bracket_position == '7/8'}.first
  if seventh_finals
    conso_quarter = weight.matches.select{|match| match.bracket_position == 'Conso Quarter'}
    conso_quarter.each do |match|
      if match.loser1_name == "BYE" or match.loser2_name == "BYE"
        seventh_finals.replace_loser_name_with_bye("Loser of #{match.bout_number}")
      end
    end
  end
  if fifth_finals
    conso_semis = weight.matches.select{|match| match.bracket_position == 'Conso Semis'}
    conso_semis.each do |match|
      if match.loser1_name == "BYE" or match.loser2_name == "BYE"
        fifth_finals.replace_loser_name_with_bye("Loser of #{match.bout_number}")
      end
    end
  end
 end
end
