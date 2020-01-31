class DoubleEliminationAdvance

 def initialize(wrestler,last_match)
		@wrestler = wrestler
		@last_match = last_match
    @next_match_position_number = (@last_match.bracket_position_number / 2.0)
 end

 def bracket_advancement
   if @last_match.winner_id == @wrestler.id
	    winner_advance
   end
   if @last_match.winner_id != @wrestler.id
	    loser_advance
   end
   advance_double_byes
 end

 def winner_advance
  if (@last_match.loser1_name == "BYE" or @last_match.loser2_name == "BYE") and @last_match.is_championship_match
    update_consolation_bye
  end
  if @last_match.bracket_position == "Quarter"
     new_match = Match.where("bracket_position = ? AND bracket_position_number = ? AND weight_id = ?","Semis",@next_match_position_number.ceil,@wrestler.weight_id).first
     update_new_match(new_match, get_wrestler_number)
  elsif @last_match.bracket_position == "Semis"
     new_match = Match.where("bracket_position = ? AND bracket_position_number = ? AND weight_id = ?","1/2",@next_match_position_number.ceil,@wrestler.weight_id).first
     update_new_match(new_match, get_wrestler_number)
  elsif @last_match.bracket_position == "Conso Semis"
     # if its a regular double elim
     if Match.where("bracket_position = ? AND bracket_position_number = ? AND weight_id = ?","Conso Semis",@next_match_position_number.ceil,@wrestler.weight_id).first.loser1_name != nil
      new_match = Match.where("bracket_position = ? AND bracket_position_number = ? AND weight_id = ?","3/4",@next_match_position_number.ceil,@wrestler.weight_id).first
      update_new_match(new_match, get_wrestler_number)
     # if it's a special bracket where consolations wrestler for 5th
     else
       new_match = Match.where("bracket_position = ? AND bracket_position_number = ? AND weight_id = ?","5/6",@next_match_position_number.ceil,@wrestler.weight_id).first
       update_new_match(new_match, get_wrestler_number)
     end
  elsif @last_match.bracket_position == "Conso Quarter"
     next_round_matches = Match.where("weight_id = ? and bracket_position = ?", @wrestler.weight_id, "Conso Semis").sort_by{|m| m.round}
     this_round_matches = Match.where("weight_id = ? and round = ? and bracket_position = ?", @wrestler.weight_id, @last_match.round, "Conso Quarter")
     if next_round_matches.size == this_round_matches.size
       # if a semi loser is dropping down
       new_match = Match.where("bracket_position = ? AND bracket_position_number = ? AND weight_id = ?","Conso Semis",@last_match.bracket_position_number,@wrestler.weight_id).first
       update_new_match(new_match,2)
     else
       # if it's a special bracket where a semi loser is not dropping down
       new_match = Match.where("bracket_position = ? AND bracket_position_number = ? AND weight_id = ?","Conso Semis",@next_match_position_number.ceil,@wrestler.weight_id).first
       update_new_match(new_match, get_wrestler_number)
     end
  elsif @last_match.bracket_position == "Bracket"
     new_match = Match.where("bracket_position_number = ? and weight_id = ? and round > ? and (bracket_position = ? or bracket_position = ?)", @next_match_position_number.ceil,@wrestler.weight_id, @last_match.round , "Bracket", "Quarter").sort_by{|m| m.round}.first
     update_new_match(new_match, get_wrestler_number)
  elsif @last_match.bracket_position == "Conso"
     next_round = next_round_matches = Match.where("weight_id = ? and round > ? and (bracket_position = ? or bracket_position = ?)", @wrestler.weight_id, @last_match.round, "Conso", "Conso Quarter").sort_by{|m| m.round}.first.round
     next_round_matches = Match.where("weight_id = ? and round = ? and (bracket_position = ? or bracket_position = ?)", @wrestler.weight_id, next_round, "Conso", "Conso Quarter")
     this_round_matches = Match.where("weight_id = ? and round = ? and (bracket_position = ? or bracket_position = ?)", @wrestler.weight_id, @last_match.round, "Conso", "Conso Quarter")
     # if a loser is dropping down
     if next_round_matches.size == this_round_matches.size
       new_match = Match.where("bracket_position_number = ? and weight_id = ? and round > ? and (bracket_position = ? or bracket_position = ?)", @last_match.bracket_position_number,@wrestler.weight_id, @last_match.round, "Conso", "Conso Quarter").sort_by{|m| m.round}.first
       update_new_match(new_match, 2)
     else
       new_match = Match.where("bracket_position_number = ? and weight_id = ? and round > ? and (bracket_position = ? or bracket_position = ?)", @next_match_position_number.ceil,@wrestler.weight_id, @last_match.round, "Conso", "Conso Quarter").sort_by{|m| m.round}.first
       update_new_match(new_match, get_wrestler_number)
     end
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

 def loser_advance
    bout = @last_match.bout_number
    next_match = Match.where("(loser1_name = ? OR loser2_name = ?) AND weight_id = ?","Loser of #{bout}","Loser of #{bout}",@wrestler.weight_id)
    if next_match.size > 0
      next_match = next_match.first
     	next_match.replace_loser_name_with_wrestler(@wrestler,"Loser of #{bout}")
      if next_match.loser1_name == "BYE" or next_match.loser2_name == "BYE"
        next_match.winner_id = @wrestler.id
        next_match.win_type = "BYE"
        next_match.finished = 1
        next_match.save
        next_match.advance_wrestlers
      end
    end
 end

 def advance_double_byes
   weight = @wrestler.weight
   weight.matches.select{|m| m.loser1_name == "BYE" and m.loser2_name == "BYE" and m.finished != 1}.each do |match|
      match.finished = 1
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
end
