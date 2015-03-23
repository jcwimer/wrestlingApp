class Poolbracket
    attr_accessor :weight
    
    def generateBracketMatches(matches,weight,highest_round)
        if weight.pool_bracket_type == "twoPoolsToSemi"
            
        elsif weight.pool_bracket_type == "twoPoolToFinal"
        
        elsif weight.pool_bracket_type == "fourPoolsToQuarter"
        
        elsif weight.pool_bracket_type == "fourPoolsToSemi"
            matches = fourPoolsToSemi(matches,weight,highest_round)
        end
        return matches
    end
    
    def fourPoolsToSemi(matches,weight,round)
        @round = round + 1
        matches = createMatchup(matches,weight,@round,"Winner Pool 1","Winner Pool 4","Semis")
        matches = createMatchup(matches,weight,@round,"Winner Pool 2","Winner Pool 3","Semis")
        matches = createMatchup(matches,weight,@round,"Runner Up Pool 1","Runner Up Pool 4","Conso Semis")
        matches = createMatchup(matches,weight,@round,"Runner Up Pool 2","Runner Up Pool 3","Conso Semis")
        matches = assignBouts(matches)
        @round = @round + 1
        @matches = matches.select{|m| m.weight_id == weight.id}
        matches = createMatchup(matches,weight,@round,"","","1/2")
        @match1 = @matches.select{|m| m.w1_name == "Winner Pool 1"}.first
        @match2 = @matches.select{|m| m.w1_name == "Winner Pool 2"}.first
        matches = createMatchup(matches,weight,@round,"Loser of #{@match1.boutNumber}","Loser of #{@match2.boutNumber}","3/4")
        matches = createMatchup(matches,weight,@round,"","","5/6")
        @match1 = @matches.select{|m| m.w1_name == "Runner Up Pool 1"}.first
        @match2 = @matches.select{|m| m.w1_name == "Runner Up Pool 2"}.first
        matches = createMatchup(matches,weight,@round,"Loser of #{@match1.boutNumber}","Loser of #{@match2.boutNumber}","7/8")
        return matches
    end
    
    def createMatchup(matches,weight,round,w1_name,w2_name,bracket_position)
        @match = Matchup.new
		@match.w1_name = w1_name
		@match.w2_name = w2_name
		@match.weight_id = weight.id
		@match.round = round
		@match.bracket_position = bracket_position
		matches << @match
		return matches
    end
    
    def assignBouts(matches)
		@bouts = Bout.new
		@matches = @bouts.assignBouts(matches)
		return @matches
	end
end