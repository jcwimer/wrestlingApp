class Poolbracket
    attr_accessor :weight
    
    def generateBracketMatches(matches,weight,highest_round)
        if weight.pool_bracket_type == "twoPoolsToSemi"
            matches = twoPoolsToSemi(matches,weight,highest_round) 
        elsif weight.pool_bracket_type == "twoPoolsToFinal"
            matches = twoPoolsToFinal(matches,weight,highest_round)
        elsif weight.pool_bracket_type == "fourPoolsToQuarter"
            matches = fourPoolsToQuarter(matches,weight,highest_round) 
        elsif weight.pool_bracket_type == "fourPoolsToSemi"
            matches = fourPoolsToSemi(matches,weight,highest_round)
        end
        return matches
    end
    
    def twoPoolsToSemi(matches,weight,round)
       @round = round + 1 
       matches = createMatchup(matches,weight,@round,"Winner Pool 1","Runner Up Pool 2","Semis",nil)
       matches = createMatchup(matches,weight,@round,"Winner Pool 2","Runner Up Pool 1","Semis",nil)
       matches = assignBouts(matches)
       @round = @round + 1
       @matches = matches.select{|m| m.weight_id == weight.id}
       @match1 = @matches.select{|m| m.w1_name == "Winner Pool 1"}.first
       @match2 = @matches.select{|m| m.w1_name == "Winner Pool 2"}.first
       matches = createMatchup(matches,weight,@round,"","","1/2",nil)
       matches = createMatchup(matches,weight,@round,"Loser of #{@match1.boutNumber}","Loser of #{@match2.boutNumber}","3/4",nil)
    end
    
    def twoPoolsToFinal(matches,weight,round)
       @round = round + 1 
       matches = createMatchup(matches,weight,@round,"Winner Pool 1","Winner Pool 2","1/2",nil)
       matches = createMatchup(matches,weight,@round,"Runner Up Pool 1","Runner Up Pool 2","3/4",nil)
    end
    
    def fourPoolsToQuarter(matches,weight,round)
       @round = round + 1 
       matches = createMatchup(matches,weight,@round,"Winner Pool 1","Runner Up Pool 2","Quarter",1)
       matches = createMatchup(matches,weight,@round,"Winner Pool 4","Runner Up Pool 3","Quarter",2)
       matches = createMatchup(matches,weight,@round,"Winner Pool 2","Runner Up Pool 1","Quarter",3)
       matches = createMatchup(matches,weight,@round,"Winner Pool 3","Runner Up Pool 4","Quarter",4)
       matches = assignBouts(matches)
       @matches = matches.select{|m| m.weight_id == weight.id}
       @match1 = @matches.select{|m| m.bracket_position_number == 1}.first
       @match2 = @matches.select{|m| m.bracket_position_number == 2}.first
       @match3 = @matches.select{|m| m.bracket_position_number == 3}.first
       @match4 = @matches.select{|m| m.bracket_position_number == 4}.first
       @round = @round + 1
       matches = createMatchup(matches,weight,@round,"","","Semis",1)
       matches = createMatchup(matches,weight,@round,"","","Semis",2)
       matches = createMatchup(matches,weight,@round,"Loser of #{@match1.boutNumber}","Loser of #{@match2.boutNumber}","Conso Semis",1)
       matches = createMatchup(matches,weight,@round,"Loser of #{@match3.boutNumber}","Loser of #{@match4.boutNumber}","Conso Semis",2)
       matches = assignBouts(matches)
       @matches = matches.select{|m| m.weight_id == weight.id}
       @round = @round + 1
       @match = @matches.select{|m| m.bracket_position == "Semis"}
       @match1 = @match.select{|m|m.bracket_position_number == 1}.first
       @match = @matches.select{|m| m.bracket_position == "Semis"}
       @match2 = @match.select{|m|m.bracket_position_number == 2}.first
       matches = createMatchup(matches,weight,@round,"","","1/2",nil)
       matches = createMatchup(matches,weight,@round,"Loser of #{@match1.boutNumber}","Loser of #{@match2.boutNumber}","3/4",nil)
       @match = @matches.select{|m| m.bracket_position == "Conso Semis"}
       @match1 = @match.select{|m|m.bracket_position_number == 1}.first
       @match = @matches.select{|m| m.bracket_position == "Conso Semis"}
       @match2 = @match.select{|m|m.bracket_position_number == 2}.first
       matches = createMatchup(matches,weight,@round,"","","5/6",nil)
       matches = createMatchup(matches,weight,@round,"Loser of #{@match1.boutNumber}","Loser of #{@match2.boutNumber}","7/8",nil)
    end
    
    def fourPoolsToSemi(matches,weight,round)
        @round = round + 1
        matches = createMatchup(matches,weight,@round,"Winner Pool 1","Winner Pool 4","Semis",nil)
        matches = createMatchup(matches,weight,@round,"Winner Pool 2","Winner Pool 3","Semis",nil)
        matches = createMatchup(matches,weight,@round,"Runner Up Pool 1","Runner Up Pool 4","Conso Semis",nil)
        matches = createMatchup(matches,weight,@round,"Runner Up Pool 2","Runner Up Pool 3","Conso Semis",nil)
        matches = assignBouts(matches)
        @round = @round + 1
        @matches = matches.select{|m| m.weight_id == weight.id}
        matches = createMatchup(matches,weight,@round,"","","1/2",nil)
        @match1 = @matches.select{|m| m.w1_name == "Winner Pool 1"}.first
        @match2 = @matches.select{|m| m.w1_name == "Winner Pool 2"}.first
        matches = createMatchup(matches,weight,@round,"Loser of #{@match1.boutNumber}","Loser of #{@match2.boutNumber}","3/4",nil)
        matches = createMatchup(matches,weight,@round,"","","5/6",nil)
        @match1 = @matches.select{|m| m.w1_name == "Runner Up Pool 1"}.first
        @match2 = @matches.select{|m| m.w1_name == "Runner Up Pool 2"}.first
        matches = createMatchup(matches,weight,@round,"Loser of #{@match1.boutNumber}","Loser of #{@match2.boutNumber}","7/8",nil)
        return matches
    end
    
    def createMatchup(matches,weight,round,w1_name,w2_name,bracket_position,bracket_position_number)
        @match = Matchup.new
		@match.w1_name = w1_name
		@match.w2_name = w2_name
		@match.weight_id = weight.id
		@match.round = round
		@match.bracket_position = bracket_position
		@match.bracket_position_number = bracket_position_number
		matches << @match
		return matches
    end
    
    def assignBouts(matches)
		@bouts = Bout.new
		@matches = @bouts.assignBouts(matches)
		return @matches
    end
end