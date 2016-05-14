class SwapWrestlers
    attr_accessor :wrestler1_id, :wrestler2_id

    
    def swapWrestlers(wrestler1_id,wrestler2_id)
	    w1 = Wrestler.find(wrestler1_id)
	    w2 = Wrestler.find(wrestler2_id)
	    
	    #placeholder guy
 	    w3 = Wrestler.new
 	    w3.weight_id = w1.weight_id
 	    w3.original_seed = w1.original_seed
 	    w3.seed = w1.seed
 		swapWrestlerMatches(w1.allMatches,w1.id,w3.id)
  	    
 	    #Swap wrestler 1 and wrestler 2
 	    swapWrestlerMatches(w2.allMatches,w2.id,w1.id)
 	    w1.seed = w2.seed

  	    
 	    swapWrestlerMatches(w3.allMatches,w3.id,w2.id)
 	    w2.seed = w3.seed

  	    
  	    w1.save
  	    w2.save
	end
	
	def swapWrestlerMatches(matchesToSwap,w1_id,w2_id)
		matchesToSwap.each do |m|
			if m.bracket_position == "Pool"
			    if m.w1 == w1_id
        			m.w1 = w2_id
        			m.save
        		elsif m.w2 == w1_id
        			m.w2 = w2_id
        			m.save
        		end
	    	end
	    end
	end
end
