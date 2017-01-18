class PoolToBracketMatchGeneration
   def initialize( tournament )
      @tournament = tournament
    end
    
    def generatePoolToBracketMatchesWeight(weight)
    	PoolGeneration.new(weight).generatePools()
        last_match = @tournament.matches.where(weight: weight).order(round: :desc).limit(1).first
        highest_round = last_match.round
        PoolBracketGeneration.new(weight, highest_round).generateBracketMatches()
        setOriginalSeedsToWrestleLastPoolRound(weight)
    end
	
	def generatePoolToBracketMatches
        @tournament.weights.order(:max).each do |weight|
          PoolGeneration.new(weight).generatePools()
          last_match = @tournament.matches.where(weight: weight).order(round: :desc).limit(1).first
          highest_round = last_match.round
          PoolBracketGeneration.new(weight, highest_round).generateBracketMatches()
        end
        movePoolSeedsToFinalPoolRound
    end
    
    def movePoolSeedsToFinalPoolRound
	    @tournament.weights.each do |w|
	      setOriginalSeedsToWrestleLastPoolRound(w)
	    end
  	end
    
    def setOriginalSeedsToWrestleLastPoolRound(weight)
		pool = 1
		until pool > weight.pools
			wrestler1 = weight.poolSeedOrder(pool).first
			wrestler2 = weight.poolSeedOrder(pool).second
			match = wrestler1.poolMatches.sort_by{|m| m.round}.last
			if match.w1 != wrestler2.id or match.w2 != wrestler2.id
				if match.w1 == wrestler1.id
					SwapWrestlers.new.swapWrestlers(match.w2,wrestler2.id)
				elsif match.w2 == wrestler1.id
					SwapWrestlers.new.swapWrestlers(match.w1,wrestler2.id)
				end
			end
		    pool += 1
		end
	end 
	
	
	def assignLoserNames
		PoolToBracketGenerateLoserNames.new(@tournament).assignLoserNames	
	end
	
end