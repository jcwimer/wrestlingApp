class Pooladvance

 attr_accessor :wrestler

 def advanceWrestler
   if self.wrestler.weight.allPoolMatchesFinished(self.wrestler.generatePoolNumber) && self.wrestler.finishedBracketMatches.size == 0
     poolToBracketAdvancment
   end
   if self.wrestler.finishedBracketMatches.size != 0
	bracketAdvancment
   end
 end

 def poolToBracketAdvancment
   @pool = self.wrestler.generatePoolNumber
   #Move to correct spot in bracket from pool
   #Pool criteria
   #Wins
   #Head to head
   #Team points
   #Pin time
   #Time on mat
   #Coin flip
   #if not one pool
   if self.wrestler.weight.wrestlers.size > 6
     @poolOrder = self.wrestler.weight.poolOrder(@pool)
     #Take pool order and move winner and runner up to correct match based on w1_name and w2_name
     @matches = self.wrestler.weight.matches
     @winnerMatch = @matches.select{|m| m.loser1_name == "Winner Pool #{@pool}" || m.loser2_name == "Winner Pool #{@pool}"}.first
     @runnerUpMatch = @matches.select{|m| m.loser1_name == "Runner Up Pool #{@pool}" || m.loser2_name == "Runner Up Pool #{@pool}"}.first
     @winner = @poolOrder.first
     @runnerUp = @poolOrder.second
     @runnerUpMatch.replaceLoserNameWithWrestler(@runnerUp,"Runner Up Pool #{@pool}")
     @winnerMatch.replaceLoserNameWithWrestler(@winner,"Winner Pool #{@pool}") 
    end
end

 def bracketAdvancment
   #Move to next correct spot in bracket
   @matches = self.wrestler.finishedMatches.sort_by{|m| m.round}.reverse
   @last_match = @matches.first
   if @last_match.winner_id == self.wrestler.id
	winnerAdvance(@last_match)
   end
   if @last_match.winner_id != self.wrestler.id
	loserAdvance(@last_match)
   end
 end

 def winnerAdvance(last_match)
   #Quarter to Semis
   #Semis to 1/2
   #Conso Semis to 5/6
   @pos = last_match.bracket_position_number
   @new_pos = (@pos/2.0)
   if last_match.bracket_position == "Quarter"
     @new_match = Match.where("bracket_position = ? AND bracket_position_number = ?","Semis",@new_pos.ceil).first
   end
  if last_match.bracket_position == "Semis"
     @new_match = Match.where("bracket_position = ? AND bracket_position_number = ?","1/2",@new_pos.ceil).first
   end
  if last_match.bracket_position == "Conso Semis"
     @new_match = Match.where("bracket_position = ? AND bracket_position_number = ?","5/6",@new_pos.ceil).first
   end
  if @new_match
     if @new_pos == @new_pos.ceil
	@new_match.w2 = self.wrestler.id
	@new_match.save
     end
     if @new_pos != @new_pos.ceil
	@new_match.w1 = self.wrestler.id
	@new_match.save
     end
  end
 end

 def loserAdvance(last_match)
    @bout = last_match.bout_number
    @next_match = Match.where("loser1_name = ? or loser2_name = ?","Loser of #{@bout}","Loser of #{@bout}")
    if @next_match.size > 0
	@next_match.first.replaceLoserNameWithWrestler(self.wrestler,"Loser of #{@bout}")
    end
 end
end
