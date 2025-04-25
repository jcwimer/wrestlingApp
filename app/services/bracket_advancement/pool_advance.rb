class PoolAdvance

 def initialize(wrestler)
		@wrestler = wrestler
		@last_match = @wrestler.last_match
 end

 def advanceWrestler
   if @wrestler.weight.pools > 1 and @wrestler.finished_bracket_matches.size < 1
     poolToBracketAdvancment
   end
   if @wrestler.finished_bracket_matches.size > 0
	    bracketAdvancment
   end
 end

 def poolToBracketAdvancment
    pool = @wrestler.pool
    # This has to always run because the last match in a pool might not be a pool winner or runner up
    winner = Wrestler.where("weight_id = ? and pool_placement = 1 and pool = ?",@wrestler.weight.id, pool).first
    runner_up = Wrestler.where("weight_id = ? and pool_placement = 2 and pool = ?",@wrestler.weight.id, pool).first
    if runner_up
      runner_up_match = Match.where("weight_id = ? and (loser1_name = ? or loser2_name = ?)",@wrestler.weight.id, "Runner Up Pool #{pool}", "Runner Up Pool #{pool}").first
      runner_up_match.replace_loser_name_with_wrestler(runner_up,"Runner Up Pool #{pool}")
    end
    if winner
      winner_match = Match.where("weight_id = ? and (loser1_name = ? or loser2_name = ?)",@wrestler.weight.id, "Winner Pool #{pool}", "Winner Pool #{pool}").first
      winner_match.replace_loser_name_with_wrestler(winner,"Winner Pool #{pool}") 
    end
 end

 def bracketAdvancment
   advance_wrestlers
 end

 def advance_wrestlers
    # Advance winner
    if @last_match.winner == @wrestler
      winner_advance
    # Advance loser
    elsif @last_match.winner != @wrestler
      loser_advance
    end
 end

 def winner_advance
   if @wrestler.last_match.bracket_position == "Quarter"
     new_match = Match.where("bracket_position = ? AND bracket_position_number = ? AND weight_id = ?","Semis",@wrestler.next_match_position_number.ceil,@wrestler.weight_id).first
     updateNewMatch(new_match)
   end
  if @wrestler.last_match.bracket_position == "Semis"
     new_match = Match.where("bracket_position = ? AND bracket_position_number = ? AND weight_id = ?","1/2",@wrestler.next_match_position_number.ceil,@wrestler.weight_id).first
     updateNewMatch(new_match)
  end
  if @wrestler.last_match.bracket_position == "Conso Semis"
     new_match = Match.where("bracket_position = ? AND bracket_position_number = ? AND weight_id = ?","5/6",@wrestler.next_match_position_number.ceil,@wrestler.weight_id).first
     updateNewMatch(new_match)
  end

 end
 
 def updateNewMatch(match)
     if @wrestler.next_match_position_number == @wrestler.next_match_position_number.ceil
	      match.w2 = @wrestler.id
      	match.save
     end
     if @wrestler.next_match_position_number != @wrestler.next_match_position_number.ceil
	      match.w1 = @wrestler.id
	      match.save
     end
 end

 def loser_advance
    bout = @wrestler.last_match.bout_number
    next_match = Match.where("(loser1_name = ? OR loser2_name = ?) AND weight_id = ?","Loser of #{bout}","Loser of #{bout}",@wrestler.weight_id)
    if next_match.size > 0
     	next_match.first.replace_loser_name_with_wrestler(@wrestler,"Loser of #{bout}")
    end
 end
end
