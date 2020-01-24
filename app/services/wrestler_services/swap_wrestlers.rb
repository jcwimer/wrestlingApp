class SwapWrestlers
    attr_accessor :wrestler1_id, :wrestler2_id

    
    def swap_wrestlers_bracket_lines(wrestler1_id,wrestler2_id)
	    w1 = Wrestler.find(wrestler1_id)
	    w2 = Wrestler.find(wrestler2_id)
	    weight_matches = w1.weight.matches
	    
	    #placeholder guy
 	    w3 = Wrestler.new
 	    w3.weight_id = w1.weight_id
 	    w3.original_seed = w1.original_seed
 	    w3.bracket_line = w1.bracket_line
 	    w3.pool = w1.pool
 		weight_matches = swapWrestlerMatches(weight_matches,w1.id,w3.id)
  	    
 	    #Swap wrestler 1 and wrestler 2
 	    weight_matches = swapWrestlerMatches(weight_matches,w2.id,w1.id)
 	    w1.bracket_line = w2.bracket_line
 	    w1.pool = w2.pool

  	    
 	    weight_matches = swapWrestlerMatches(weight_matches,w3.id,w2.id)
 	    w2.bracket_line = w3.bracket_line
 	    w2.pool = w3.pool

  	    save_matches(weight_matches)
  	    w1.save
  	    w2.save
	end

	def save_matches(matches)
        matches.each do |match|
        	match.save
        end
    end
	
	def swapWrestlerMatches(matchesToSwap,from_id,to_id)
		matchesToSwap.select{|m| m.w1 == from_id or m.w2 == from_id}.each do |m|
			# if m.bracket_position == "Pool" or (m.bracket_position == "Bracket" and m.round == 1)
			    if m.w1 == from_id
        			m.w1 = to_id
        		elsif m.w2 == from_id
        			m.w2 = to_id
        		end
        		if m.winner_id == from_id
        			m.winner_id = to_id
        		end
        		# m.save
	    	# end
	    end
	    return matchesToSwap
	end
end
