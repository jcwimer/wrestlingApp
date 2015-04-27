class Poolbracket

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
       matches = createMatchup(matches,weight,@round,"Winner Pool 1","Runner Up Pool 2","Semis",1)
       matches = createMatchup(matches,weight,@round,"Winner Pool 2","Runner Up Pool 1","Semis",2)
       @round = @round + 1
       @matches = matches.select{|m| m.weight_id == weight.id}
       matches = createMatchup(matches,weight,@round,"","","1/2",1)
       matches = createMatchup(matches,weight,@round,"","","3/4",1)
      return matches
    end
    
    def twoPoolsToFinal(matches,weight,round)
       @round = round + 1 
       matches = createMatchup(matches,weight,@round,"Winner Pool 1","Winner Pool 2","1/2",1)
       matches = createMatchup(matches,weight,@round,"Runner Up Pool 1","Runner Up Pool 2","3/4",1)
      return matches
    end
    
    def fourPoolsToQuarter(matches,weight,round)
       @round = round + 1 
       matches = createMatchup(matches,weight,@round,"Winner Pool 1","Runner Up Pool 2","Quarter",1)
       matches = createMatchup(matches,weight,@round,"Winner Pool 4","Runner Up Pool 3","Quarter",2)
       matches = createMatchup(matches,weight,@round,"Winner Pool 2","Runner Up Pool 1","Quarter",3)
       matches = createMatchup(matches,weight,@round,"Winner Pool 3","Runner Up Pool 4","Quarter",4)
       @round = @round + 1
       matches = createMatchup(matches,weight,@round,"","","Semis",1)
       matches = createMatchup(matches,weight,@round,"","","Semis",2)
       matches = createMatchup(matches,weight,@round,"","","Conso Semis",1)
       matches = createMatchup(matches,weight,@round,"","","Conso Semis",2)
       @round = @round + 1
       matches = createMatchup(matches,weight,@round,"","","1/2",1)
       matches = createMatchup(matches,weight,@round,"","","3/4",1)
       matches = createMatchup(matches,weight,@round,"","","5/6",1)
       matches = createMatchup(matches,weight,@round,"","","7/8",1)
      return matches
    end
    
    def fourPoolsToSemi(matches,weight,round)
        @round = round + 1
        matches = createMatchup(matches,weight,@round,"Winner Pool 1","Winner Pool 4","Semis",1)
        matches = createMatchup(matches,weight,@round,"Winner Pool 2","Winner Pool 3","Semis",2)
        matches = createMatchup(matches,weight,@round,"Runner Up Pool 1","Runner Up Pool 4","Conso Semis",1)
        matches = createMatchup(matches,weight,@round,"Runner Up Pool 2","Runner Up Pool 3","Conso Semis",2)
        @round = @round + 1
        matches = createMatchup(matches,weight,@round,"","","1/2",1)
        matches = createMatchup(matches,weight,@round,"","","3/4",1)
        matches = createMatchup(matches,weight,@round,"","","5/6",1)
        matches = createMatchup(matches,weight,@round,"","","7/8",1)
        return matches
    end
    
    def createMatchup(matches,weight,round,w1_name,w2_name,bracket_position,bracket_position_number)
    @match = Match.new
		@match.loser1_name = w1_name
		@match.loser2_name = w2_name
		@match.weight_id = weight.id
		@match.round = round
		@match.bracket_position = bracket_position
		@match.bracket_position_number = bracket_position_number
		matches << @match
		return matches
    end
    

end