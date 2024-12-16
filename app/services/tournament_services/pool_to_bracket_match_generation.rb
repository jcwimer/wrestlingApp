class PoolToBracketMatchGeneration
   def initialize( tournament )
      @tournament = tournament
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
			wrestler1 = weight.pool_wrestlers_sorted_by_bracket_line(pool).first
			wrestler2 = weight.pool_wrestlers_sorted_by_bracket_line(pool).second
			match = wrestler1.pool_matches.sort_by{|m| m.round}.last
			if match.w1 != wrestler2.id or match.w2 != wrestler2.id
				if match.w1 == wrestler1.id
					SwapWrestlers.new.swap_wrestlers_bracket_lines(match.w2,wrestler2.id)
				elsif match.w2 == wrestler1.id
					SwapWrestlers.new.swap_wrestlers_bracket_lines(match.w1,wrestler2.id)
				end
			end
		    pool += 1
		end
	end 
	
	
	def assignLoserNames
		PoolToBracketGenerateLoserNames.new(@tournament).assignLoserNames	
	end
	
end