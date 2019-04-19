class PoolOrder
	def initialize(wrestlers)
		@wrestlers = wrestlers
	end

	def getPoolOrder
	    setOriginalPoints
	    while checkForTieBreakers == true
	        breakTie
	    end
	    @wrestlers.sort_by{|w| w.poolAdvancePoints}.reverse.each_with_index do |wrestler, index|
          placement = index + 1
          wrestler.pool_placement = placement
          wrestler.save
	    end
	    @wrestlers.sort_by{|w| w.poolAdvancePoints}.reverse!
	end
	
	def setOriginalPoints
	   @wrestlers.each do |w|
	       w.poolAdvancePoints = w.pool_wins.size
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
		#ifWrestlersWithSamePointsIsSameAsOriginal(originalTieSize) { deductedPoints }
		if originalTieSize == 2
	    	ifWrestlersWithSamePointsIsSameAsOriginal(originalTieSize) { headToHead }
		end
		ifWrestlersWithSamePointsIsSameAsOriginal(originalTieSize) { teamPoints }
		ifWrestlersWithSamePointsIsSameAsOriginal(originalTieSize) { mostFalls }
		ifWrestlersWithSamePointsIsSameAsOriginal(originalTieSize) { mostTechs }
		ifWrestlersWithSamePointsIsSameAsOriginal(originalTieSize) { mostMajors }
		ifWrestlersWithSamePointsIsSameAsOriginal(originalTieSize) { mostDecisionPointsScored }
		ifWrestlersWithSamePointsIsSameAsOriginal(originalTieSize) { fastest_pins }
		ifWrestlersWithSamePointsIsSameAsOriginal(originalTieSize) { coinFlip }
	end
	
	
	def headToHead
	   wrestlersWithSamePoints.each do |wr|
	        otherWrestler = wrestlersWithSamePoints.select{|w| w.id != wr.id}.first
	        if wr.match_against(otherWrestler).first.winner_id == wr.id
	        	addPointsToWrestlersAhead(wr)
	        	wr.pool_placement_tiebreaker = "Head to Head"
		        wr.save
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
			pointsArray << w.total_points_deducted
		end
		leastPoints = pointsArray.min
		wrestlersWithLeastDeductedPoints = wrestlersWithSamePoints.select{|w| w.total_points_deducted == leastPoints}
		addPointsToWrestlersAhead(wrestlersWithLeastDeductedPoints.first)
		wrestlersWithLeastDeductedPoints.each do |wr|
			wr.pool_placement_tiebreaker = "Least Deducted Points"
		    wr.save
			addPoints(wr)	
		end
	end
	
	def mostDecisionPointsScored
		pointsArray = []
		wrestlersWithSamePoints.each do |w|
			pointsArray << w.decision_points_scored
		end
		mostPoints = pointsArray.max
		wrestlersWithMostPoints = wrestlersWithSamePoints.select{|w| w.decision_points_scored == mostPoints}
		addPointsToWrestlersAhead(wrestlersWithMostPoints.first)
		wrestlersWithMostPoints.each do |wr|
			wr.pool_placement_tiebreaker = "Points Scored"
		    wr.save
			addPoints(wr)
		end
		secondPoints = pointsArray.sort[-2]
		wrestlersWithSecondMostPoints = wrestlersWithSamePoints.select{|w| w.decision_points_scored == secondPoints}
		addPointsToWrestlersAhead(wrestlersWithSecondMostPoints.first)
		wrestlersWithSecondMostPoints.each do |wr|
			wr.pool_placement_tiebreaker = "Points Scored"
		    wr.save
			addPoints(wr)
		end
	end
	
	def fastest_pins
		wrestlersWithSamePointsWithPins = []
		wrestlersWithSamePoints.each do |wr|
			if wr.pin_wins.size > 0
				wrestlersWithSamePointsWithPins << wr	
			end
		end
		if wrestlersWithSamePointsWithPins.size > 0
			fastest = wrestlersWithSamePointsWithPins.sort_by{|w| w.fastest_pin.pin_time_in_seconds}.first.fastest_pin
			secondFastest = wrestlersWithSamePointsWithPins.sort_by{|w| w.fastest_pin.pin_time_in_seconds}.second.fastest_pin
			wrestlersWithFastestPin = wrestlersWithSamePointsWithPins.select{|w| w.fastest_pin.pin_time_in_seconds == fastest.pin_time_in_seconds}
			addPointsToWrestlersAhead(wrestlersWithFastestPin.first)
			wrestlersWithFastestPin.each do |wr|
				wr.pool_placement_tiebreaker = "Pin Time"
		        wr.save
				addPoints(wr)
			end
			
			wrestlersWithSecondFastestPin = wrestlersWithSamePointsWithPins.select{|w| w.fastest_pin.pin_time_in_seconds == secondFastest.pin_time_in_seconds}
			addPointsToWrestlersAhead(wrestlersWithSecondFastestPin.first)
			wrestlersWithSecondFastestPin.each do |wr|
				wr.pool_placement_tiebreaker = "Pin Time"
		        wr.save
				addPoints(wr)
			end
		end
	end
	
	def teamPoints
		pointsArray = []
		wrestlersWithSamePoints.each do |w|
			pointsArray << w.total_pool_points_for_pool_order
		end
		mostPoints = pointsArray.max
		wrestlersSortedByTeamPoints = wrestlersWithSamePoints.select{|w| w.total_pool_points_for_pool_order == mostPoints}
		addPointsToWrestlersAhead(wrestlersSortedByTeamPoints.first)
		wrestlersSortedByTeamPoints.each do |wr|
			wr.pool_placement_tiebreaker = "Team Points"
		    wr.save
			addPoints(wr)	
		end	
	end
	
	def mostFalls
		pointsArray = []
		wrestlersWithSamePoints.each do |w|
			pointsArray << w.pin_wins.size
		end
		mostPoints = pointsArray.max
		wrestlersSortedByFallWins = wrestlersWithSamePoints.select{|w| w.pin_wins.size == mostPoints}
		addPointsToWrestlersAhead(wrestlersSortedByFallWins.first)
		wrestlersSortedByFallWins.each do |wr|
			wr.pool_placement_tiebreaker = "Most Pins"
		    wr.save
			addPoints(wr)	
		end	
	end
	
	def mostTechs
		pointsArray = []
		wrestlersWithSamePoints.each do |w|
			pointsArray << w.tech_wins.size
		end
		mostPoints = pointsArray.max
		wrestlersSortedByTechWins = wrestlersWithSamePoints.select{|w| w.tech_wins.size == mostPoints}
		addPointsToWrestlersAhead(wrestlersSortedByTechWins.first)
		wrestlersSortedByTechWins.each do |wr|
			wr.pool_placement_tiebreaker = "Most Techs"
		    wr.save
			addPoints(wr)	
		end	
	end
	
	def mostMajors
		pointsArray = []
		wrestlersWithSamePoints.each do |w|
			pointsArray << w.major_wins.size
		end
		mostPoints = pointsArray.max
		wrestlersSortedByMajorWins = wrestlersWithSamePoints.select{|w| w.major_wins.size == mostPoints}
		addPointsToWrestlersAhead(wrestlersSortedByMajorWins.first)
		wrestlersSortedByMajorWins.each do |wr|
			wr.pool_placement_tiebreaker = "Most Majors"
		    wr.save
			addPoints(wr)	
		end	
	end
	
	def coinFlip
		wrestler = wrestlersWithSamePoints.sample
		wrestler.pool_placement_tiebreaker = "Coin Flip"
		wrestler.save
		addPointsToWrestlersAhead(wrestler)
	    addPoints(wrestler)
	end
end
