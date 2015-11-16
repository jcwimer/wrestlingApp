class Poolorder
	def initialize(wrestlers)
		@wrestlers = wrestlers
	end

	def getPoolOrder
	    setOriginalPoints
	    while checkForTieBreakers == true
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
	    if wrestlersWithSamePoints.size > 1
	       return true
	    end
	    return false
	end
	
	def wrestlersWithSamePoints
		@wrestlers.each do |w|
	       wrestlersWithSamePoints = @wrestlers.select{|wr| wr.poolAdvancePoints == w.poolAdvancePoints}
	       if wrestlersWithSamePoints.size > 0
	       	 return wrestlersWithSamePoints
	       end
	    end
	end
	
	def ifWrestlersWithSamePointsIsSameAsOriginal(originalTieSize)
		if wrestlersWithSamePoints.size == originalTieSize
			yield	
		end
	end
	
	def breakTie
		originalTieSize = wrestlersWithSamePoints.size
		if originalTieSize == 2
	    	ifWrestlersWithSamePointsIsSameAsOriginal(originalTieSize) { headToHead }
		end
		ifWrestlersWithSamePointsIsSameAsOriginal(originalTieSize) { deductedPoints }
		ifWrestlersWithSamePointsIsSameAsOriginal(originalTieSize) { teamPoints }
		ifWrestlersWithSamePointsIsSameAsOriginal(originalTieSize) { coinFlip }
	end
	
	
	def headToHead
	   wrestlersWithSamePoints.each do |wr|
	        otherWrestler = wrestlersWithSamePoints.select{|w| w.id != wr.id}.first
	        if wr.matchAgainst(otherWrestler).first.winner_id == wr.id
	        	addPointsToWrestlersAhead(wr)
	            addPoints(wr)
	        end
	   end
	end
	
	def addPoints(wrestler)
		wrestler.poolAdvancePoints = wrestler.poolAdvancePoints + 1
	end
	
	def addPointsToWrestlersAhead(wrestler)
		wrestlersAhead = @wrestlers.select{|w| w.poolAdvancePoints > wrestler.poolAdvancePoints}
		wrestlersAhead.each do |wr|
			wr.poolAdvancePoints = wr.poolAdvancePoints + 1
		end
	end
	
	def deductedPoints
		pointsArray = []
		wrestlersWithSamePoints.each do |w|
			pointsArray << w.totalDeductedPoints
		end
		leastPoints = pointsArray.min
		wrestlersWithLeastDeductedPoints = wrestlersWithSamePoints.select{|w| w.totalDeductedPoints == leastPoints}
		addPointsToWrestlersAhead(wrestlersWithLeastDeductedPoints.first)
		wrestlersWithLeastDeductedPoints.each do |wr|
			addPoints(wr)	
		end
	end
	
	def teamPoints
		pointsArray = []
		wrestlersWithSamePoints.each do |w|
			pointsArray << w.totalTeamPoints
		end
		mostPoints = pointsArray.max
		wrestlersWithLeastDeductedPoints = wrestlersWithSamePoints.select{|w| w.totalTeamPoints == mostPoints}
		addPointsToWrestlersAhead(wrestlersWithLeastDeductedPoints.first)
		wrestlersWithLeastDeductedPoints.each do |wr|
			addPoints(wr)	
		end	
	end
	
	def coinFlip
		wrestler = wrestlersWithSamePoints.sample
		addPointsToWrestlersAhead(wrestler)
	    addPoints(wrestler)
	end
end