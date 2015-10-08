class Pooladvance

 attr_accessor :wrestler

 def poolRank
   #Give wrestlers pool points then give extra points for tie breakers and spit them out
   #in order from first to last
   #Calculate wrestlers pool points in their model
   #Order wrestlers by pool in the weight model
 end

 def advanceWrestler
   if self.wrestler.poolMatches.size > self.wrestler.finishedMatches.size
	exit
   end
   poolToBracketAdvancment
   bracketAdvancment
 end

 def poolToBracketAdvancment
   @pool = self.wrestler.generatePoolNumber
   @poolWrestlers = self.wrestler.weight.wrestlers_for_pool(@pool)
   @poolWrestlers.each do |w|  
     if w.finishedBracketMatches.size > 0
	exit
     end
   end
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

     @poolOrder = self.wrestler.weight.poolOrder
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
 end


end
