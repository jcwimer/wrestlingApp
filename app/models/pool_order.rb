class PoolOrder
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
		ifWrestlersWithSamePointsIsSameAsOriginal(originalTieSize) { mostFalls }
		ifWrestlersWithSamePointsIsSameAsOriginal(originalTieSize) { mostTechs }
		ifWrestlersWithSamePointsIsSameAsOriginal(originalTieSize) { mostMajors }
		ifWrestlersWithSamePointsIsSameAsOriginal(originalTieSize) { mostDecisionPointsScored }
		ifWrestlersWithSamePointsIsSameAsOriginal(originalTieSize) { fastestPin }
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
	
	def mostDecisionPointsScored
		pointsArray = []
		wrestlersWithSamePoints.each do |w|
			pointsArray << w.decisionPointsScored
		end
		mostPoints = pointsArray.max
		wrestlersWithMostPoints = wrestlersWithSamePoints.select{|w| w.decisionPointsScored == mostPoints}
		addPointsToWrestlersAhead(wrestlersWithMostPoints.first)
		wrestlersWithMostPoints.each do |wr|
			addPoints(wr)
		end
		secondPoints = pointsArray.sort[-2]
		wrestlersWithSecondMostPoints = wrestlersWithSamePoints.select{|w| w.decisionPointsScored == secondPoints}
		addPointsToWrestlersAhead(wrestlersWithSecondMostPoints.first)
		wrestlersWithSecondMostPoints.each do |wr|
			addPoints(wr)
		end
	end
	
	def fastestPin
		timeArray = []
		wrestlersWithSamePoints.each do |w|
			timeArray << w.fastestPin
		end
		fastest = timeArray.max
		wrestlersWithFastestPin = wrestlersWithSamePoints.select{|w| w.fastestPin == fastest}
		addPointsToWrestlersAhead(wrestlersWithFastestPin.first)
		wrestlersWithFastestPin.each do |wr|
			addPoints(wr)
		end
		secondFastest = timeArray.sort[-2]
		wrestlersWithSecondFastestPin = wrestlersWithSamePoints.select{|w| w.fastestPin == secondFastest}
		addPointsToWrestlersAhead(wrestlersWithSecondFastestPin.first)
		wrestlersWithSecondFastestPin.each do |wr|
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
	
	def mostFalls
		pointsArray = []
		wrestlersWithSamePoints.each do |w|
			pointsArray << w.pinWins.size
		end
		mostPoints = pointsArray.max
		wrestlersWithLeastDeductedPoints = wrestlersWithSamePoints.select{|w| w.pinWins.size == mostPoints}
		addPointsToWrestlersAhead(wrestlersWithLeastDeductedPoints.first)
		wrestlersWithLeastDeductedPoints.each do |wr|
			addPoints(wr)	
		end	
	end
	
	def mostTechs
		pointsArray = []
		wrestlersWithSamePoints.each do |w|
			pointsArray << w.techWins.size
		end
		mostPoints = pointsArray.max
		wrestlersWithLeastDeductedPoints = wrestlersWithSamePoints.select{|w| w.techWins.size == mostPoints}
		addPointsToWrestlersAhead(wrestlersWithLeastDeductedPoints.first)
		wrestlersWithLeastDeductedPoints.each do |wr|
			addPoints(wr)	
		end	
	end
	
	def mostMajors
		pointsArray = []
		wrestlersWithSamePoints.each do |w|
			pointsArray << w.majorWins.size
		end
		mostPoints = pointsArray.max
		wrestlersWithLeastDeductedPoints = wrestlersWithSamePoints.select{|w| w.majorWins.size == mostPoints}
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
