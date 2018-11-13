class PoolAdvance

 def initialize(wrestler,previousMatch)
		@wrestler = wrestler
		@previousMatch = previousMatch
 end

 def advanceWrestler
   if @wrestler.weight.all_pool_matches_finished(@wrestler.pool) && @wrestler.finished_bracket_matches.size == 0
     poolToBracketAdvancment
   end
   if @wrestler.finished_bracket_matches.size > 0
	    bracketAdvancment
   end
 end

 def poolToBracketAdvancment
   pool = @wrestler.pool
   if @wrestler.weight.wrestlers.size > 6
     pool_placement_order = @wrestler.weight.pool_placement_order(pool)
     #Take pool order and move winner and runner up to correct match based on w1_name and w2_name
     matches = @wrestler.weight.matches
     winnerMatch = matches.select{|m| m.loser1_name == "Winner Pool #{pool}" || m.loser2_name == "Winner Pool #{pool}"}.first
     runnerUpMatch = matches.select{|m| m.loser1_name == "Runner Up Pool #{pool}" || m.loser2_name == "Runner Up Pool #{pool}"}.first
     winner = pool_placement_order.first
     runnerUp = pool_placement_order.second
     runnerUpMatch.replace_loser_name_with_wrestler(runnerUp,"Runner Up Pool #{pool}")
     winnerMatch.replace_loser_name_with_wrestler(winner,"Winner Pool #{pool}") 
   end
 end

 def bracketAdvancment
   if @previousMatch.winner_id == @wrestler.id
	    winnerAdvance
   end
   if @previousMatch.winner_id != @wrestler.id
	    loserAdvance
   end
 end

 def winnerAdvance
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

 def loserAdvance
    bout = @wrestler.last_match.bout_number
    next_match = Match.where("(loser1_name = ? OR loser2_name = ?) AND weight_id = ?","Loser of #{bout}","Loser of #{bout}",@wrestler.weight_id)
    if next_match.size > 0
     	next_match.first.replace_loser_name_with_wrestler(@wrestler,"Loser of #{bout}")
    end
 end
end
