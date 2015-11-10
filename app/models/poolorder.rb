class Poolorder
	def initialize(wrestlers)
		@wrestlers = wrestlers
	end
	attr_accessor :wrestlersWithSamePoints
	
	def getPoolOrder
	    setOriginalPoints
	    until checkForTieBreakers == false
	        breakTie
	    end
	    @wrestlers.sort_by{|w| w.poolAdvancePoints}.reverse!
	end
	
	def setOriginalPoints
	   @wrestlers.each do |w|
	       w.poolAdvancePoints = w.poolWins.size
	   end
	end
	
	def checkForTieBreakers
	   @wrestlers.each do |w|
	       self.wrestlersWithSamePoints = @wrestlers.select{|wr| wr.poolAdvancePoints == w.poolAdvancePoints}
	       if self.wrestlersWithSamePoints.size > 1
	           return true
	       end
	    end 
	    return false
	end
	
	def breakTie
	    headToHead
	end
	
	
	def headToHead
	   self.wrestlersWithSamePoints.each do |wr|
	        @otherWrestlers = self.wrestlersWithSamePoints.select{|w| w.id != wr.id}
	        @otherWrestlers.each do |ow|
	            if wr.matchAgainst(ow).first.winner_id == wr.id
	                wr.poolAdvancePoints = wr.poolAdvancePoints + 1
	            end
	        end
	   end
	end
end