class Pooladvance

 def initialize(wrestler)
		@wrestler = wrestler
 end

 def advanceWrestler
   if @wrestler.weight.allPoolMatchesFinished(@wrestler.generatePoolNumber) && @wrestler.finishedBracketMatches.size == 0
     poolToBracketAdvancment
   end
   if @wrestler.finishedBracketMatches.size > 0
	    bracketAdvancment
   end
 end

 def poolToBracketAdvancment
   pool = @wrestler.generatePoolNumber
   if @wrestler.weight.wrestlers.size > 6
     poolOrder = @wrestler.weight.poolOrder(pool)
     #Take pool order and move winner and runner up to correct match based on w1_name and w2_name
     matches = @wrestler.weight.matches
     winnerMatch = matches.select{|m| m.loser1_name == "Winner Pool #{pool}" || m.loser2_name == "Winner Pool #{pool}"}.first
     runnerUpMatch = matches.select{|m| m.loser1_name == "Runner Up Pool #{pool}" || m.loser2_name == "Runner Up Pool #{pool}"}.first
     winner = poolOrder.first
     runnerUp = poolOrder.second
     runnerUpMatch.replaceLoserNameWithWrestler(runnerUp,"Runner Up Pool #{pool}")
     winnerMatch.replaceLoserNameWithWrestler(winner,"Winner Pool #{pool}") 
   end
 end

 def bracketAdvancment
   if @wrestler.winnerOfLastMatch?
	    winnerAdvance
   end
   if !@wrestler.winnerOfLastMatch?
	    loserAdvance
   end
 end

 def winnerAdvance
   if @wrestler.lastMatch.bracket_position == "Quarter"
     new_match = Match.where("bracket_position = ? AND bracket_position_number = ? AND weight_id = ?","Semis",@wrestler.nextMatchPositionNumber.ceil,@wrestler.weight_id).first
     updateNewMatch(new_match)
   end
  if @wrestler.lastMatch.bracket_position == "Semis"
     new_match = Match.where("bracket_position = ? AND bracket_position_number = ? AND weight_id = ?","1/2",@wrestler.nextMatchPositionNumber.ceil,@wrestler.weight_id).first
     updateNewMatch(new_match)
  end
  if @wrestler.lastMatch.bracket_position == "Conso Semis"
     new_match = Match.where("bracket_position = ? AND bracket_position_number = ? AND weight_id = ?","5/6",@wrestler.nextMatchPositionNumber.ceil,@wrestler.weight_id).first
     updateNewMatch(new_match)
  end

 end
 
 def updateNewMatch(match)
     if @wrestler.nextMatchPositionNumber == @wrestler.nextMatchPositionNumber.ceil
	      match.w2 = @wrestler.id
      	match.save
     end
     if @wrestler.nextMatchPositionNumber != @wrestler.nextMatchPositionNumber.ceil
	      match.w1 = @wrestler.id
	      match.save
     end
 end

 def loserAdvance
    bout = @wrestler.lastMatch.bout_number
    next_match = Match.where("loser1_name = ? OR loser2_name = ? AND weight_id = ?","Loser of #{bout}","Loser of #{bout}",@wrestler.weight_id)
    if next_match.size > 0
     	next_match.first.replaceLoserNameWithWrestler(@wrestler,"Loser of #{bout}")
    end
 end
end
