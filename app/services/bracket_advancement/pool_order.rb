class PoolOrder
	def initialize(wrestlers)
		@wrestlers = wrestlers
	end

	def getPoolOrder
	    setOriginalPoints
	    while checkForTies(@wrestlers) == true
	        getWrestlersOrderByPoolAdvancePoints.each do |wrestler|
	        	wrestlers_with_same_points = getWrestlersOrderByPoolAdvancePoints.select{|w| w.poolAdvancePoints == wrestler.poolAdvancePoints}
	        	if wrestlers_with_same_points.size > 1
	        		breakTie(wrestlers_with_same_points)
	        	end
	        end
	    end
	    getWrestlersOrderByPoolAdvancePoints.each_with_index do |wrestler, index|
            placement = index + 1
            wrestler.pool_placement = placement
            wrestler.save
	    end
	    @wrestlers.sort_by{|w| w.poolAdvancePoints}.reverse!
	end
	
	def getWrestlersOrderByPoolAdvancePoints
	    @wrestlers.sort_by{|w| w.poolAdvancePoints}.reverse	
	end
	
	def setOriginalPoints
	   @wrestlers.each do |w|
	   	   w.pool_placement_tiebreaker = nil
	   	   w.pool_placement = nil
	       w.poolAdvancePoints = w.pool_wins.size
	   end
	end
	
	def checkForTies(wrestlers_to_check)
	    if wrestlersWithSamePoints(wrestlers_to_check).size > 1
	       return true
	    end
	    return false
	end
	
	def wrestlersWithSamePoints(wrestlers_to_check)
		wrestlers_to_check.each do |w|
	       wrestlersWithSamePointsLocal = wrestlers_to_check.select{|wr| wr.poolAdvancePoints == w.poolAdvancePoints}
	       if wrestlersWithSamePointsLocal.size > 1
	       	 return wrestlersWithSamePointsLocal
	       end
	    end
	    return []
	end
	
	def ifWrestlersWithSamePointsIsSameAsOriginal(originalTieSize,wrestlers_to_check)
		if wrestlersWithSamePoints(wrestlers_to_check).size == originalTieSize
			return true
		else 
		    return false	
		end
	end
	
	def breakTie(wrestlers_with_same_points)
		originalTieSize = wrestlers_with_same_points.size
		deductedPoints(originalTieSize,wrestlers_with_same_points) if ifWrestlersWithSamePointsIsSameAsOriginal(originalTieSize,wrestlers_with_same_points)
		if originalTieSize == 2
	    	headToHead(wrestlers_with_same_points) if ifWrestlersWithSamePointsIsSameAsOriginal(originalTieSize,wrestlers_with_same_points)
		end
		teamPoints(wrestlers_with_same_points) if ifWrestlersWithSamePointsIsSameAsOriginal(originalTieSize,wrestlers_with_same_points)
        mostFalls(wrestlers_with_same_points) if ifWrestlersWithSamePointsIsSameAsOriginal(originalTieSize,wrestlers_with_same_points)
		mostTechs(wrestlers_with_same_points) if ifWrestlersWithSamePointsIsSameAsOriginal(originalTieSize,wrestlers_with_same_points)
		mostMajors(wrestlers_with_same_points) if ifWrestlersWithSamePointsIsSameAsOriginal(originalTieSize,wrestlers_with_same_points)
		mostDecisionPointsScored(wrestlers_with_same_points) if ifWrestlersWithSamePointsIsSameAsOriginal(originalTieSize,wrestlers_with_same_points)
		fastest_pins(wrestlers_with_same_points) if ifWrestlersWithSamePointsIsSameAsOriginal(originalTieSize,wrestlers_with_same_points)
		coinFlip(wrestlers_with_same_points) if ifWrestlersWithSamePointsIsSameAsOriginal(originalTieSize,wrestlers_with_same_points)
	end
	
	
	def headToHead(wrestlers_with_same_points)
	   wrestlers_with_same_points.each do |wr|
	        otherWrestler = wrestlers_with_same_points.select{|w| w.id != wr.id}.first
	        if otherWrestler and wr.match_against(otherWrestler).select{|match| match.bracket_position == "Pool"}.first.winner_id == wr.id
	        	addPointsToWrestlersAhead(wr)
	        	wr.pool_placement_tiebreaker = "Head to Head"
	            addPoints(wr)
	        end
	   end
	end
	
	def addPoints(wrestler)
		# addPointsToWrestlersAhead(wrestler)
		# Cannot go here because if team points are the same the first with points added will stay ahead
		wrestler.poolAdvancePoints = wrestler.poolAdvancePoints + 1
	end
	
	def addPointsToWrestlersAhead(wrestler)
		wrestlersAhead = @wrestlers.select{|w| w.poolAdvancePoints > wrestler.poolAdvancePoints}
		wrestlersAhead.each do |wr|
			wr.poolAdvancePoints = wr.poolAdvancePoints + 1
		end
	end
	
	def deductedPoints(originalTieSize,wrestlers_with_same_points)
		pointsArray = []
		wrestlers_with_same_points.each do |w|
			pointsArray << w.total_points_deducted
		end
		leastPoints = pointsArray.min
		wrestlersWithLeastDeductedPoints = wrestlers_with_same_points.select{|w| w.total_points_deducted == leastPoints}
		addPointsToWrestlersAhead(wrestlersWithLeastDeductedPoints.first)
		if wrestlersWithLeastDeductedPoints.size != originalTieSize
			wrestlersWithLeastDeductedPoints.each do |wr|
				wr.pool_placement_tiebreaker = "Least Deducted Points"
				addPoints(wr)	
			end
		end
	end
	
	def mostDecisionPointsScored(wrestlers_with_same_points)
		pointsArray = []
		wrestlers_with_same_points.each do |w|
			pointsArray << w.decision_points_scored_pool
		end
		mostPoints = pointsArray.max
		wrestlersWithMostPoints = wrestlers_with_same_points.select{|w| w.decision_points_scored_pool == mostPoints}
		addPointsToWrestlersAhead(wrestlersWithMostPoints.first)
		wrestlersWithMostPoints.each do |wr|
			wr.pool_placement_tiebreaker = "Decision Points Scored"
			addPoints(wr)
		end
		secondPoints = pointsArray.sort[-2]
		wrestlersWithSecondMostPoints = wrestlers_with_same_points.select{|w| w.decision_points_scored_pool == secondPoints}
		addPointsToWrestlersAhead(wrestlersWithSecondMostPoints.first)
		wrestlersWithSecondMostPoints.each do |wr|
			wr.pool_placement_tiebreaker = "Decision Points Scored"
			addPoints(wr)
		end
	end
	
	def fastest_pins(wrestlers_with_same_points)
		wrestlersWithSamePointsWithPins = []
		wrestlers_with_same_points.each do |wr|
			if wr.pin_wins.select{|m| m.bracket_position == "Pool"}.size > 0
				wrestlersWithSamePointsWithPins << wr	
			end
		end
		if wrestlersWithSamePointsWithPins.size > 0
			fastest = wrestlersWithSamePointsWithPins.sort_by{|w| w.pin_time_pool}.first.pin_time_pool
			wrestlersWithFastestPin = wrestlersWithSamePointsWithPins.select{|w| w.pin_time_pool == fastest}
			addPointsToWrestlersAhead(wrestlersWithFastestPin.first)
			wrestlersWithFastestPin.each do |wr|
				wr.pool_placement_tiebreaker = "Pin Time"
				addPoints(wr)
			end
		end
	end
	
	def teamPoints(wrestlers_with_same_points)
		teamPointsArray = []
		wrestlers_with_same_points.each do |w|
			teamPointsArray << w.total_pool_points_for_pool_order
		end
		mostPoints = teamPointsArray.max
		wrestlersSortedByTeamPoints = wrestlers_with_same_points.select{|w| w.total_pool_points_for_pool_order == mostPoints}
		addPointsToWrestlersAhead(wrestlersSortedByTeamPoints.first)
		wrestlersSortedByTeamPoints.each do |wr|
			wr.pool_placement_tiebreaker = "Team Points"
			addPoints(wr)	
		end	
	end
	
	def mostFalls(wrestlers_with_same_points)
		mostPins = []
		wrestlers_with_same_points.each do |w|
			mostPins << w.pin_wins.select{|m| m.bracket_position == "Pool"}.size
		end
		pinsMax = mostPins.max
		wrestlersSortedByFallWins = wrestlers_with_same_points.select{|w| w.pin_wins.select{|m| m.bracket_position == "Pool"}.size == pinsMax}
		if pinsMax > 0
			addPointsToWrestlersAhead(wrestlersSortedByFallWins.first)
			wrestlersSortedByFallWins.each do |wr|
				wr.pool_placement_tiebreaker = "Most Pins"
				addPoints(wr)	
			end
		end
	end
	
	def mostTechs(wrestlers_with_same_points)
		techsArray = []
		wrestlers_with_same_points.each do |w|
			techsArray << w.tech_wins.select{|m| m.bracket_position == "Pool"}.size
		end
		mostTechsWins = techsArray.max
		wrestlersSortedByTechWins = wrestlers_with_same_points.select{|w| w.tech_wins.select{|m| m.bracket_position == "Pool"}.size == mostTechsWins}
		if mostTechsWins > 0
			addPointsToWrestlersAhead(wrestlersSortedByTechWins.first)
			wrestlersSortedByTechWins.each do |wr|
				wr.pool_placement_tiebreaker = "Most Techs"
				addPoints(wr)	
			end
		end
	end
	
	def mostMajors(wrestlers_with_same_points)
		majorsArray = []
		wrestlers_with_same_points.each do |w|
			majorsArray << w.major_wins.select{|m| m.bracket_position == "Pool"}.size
		end
		mostMajorWins = majorsArray.max
		wrestlersSortedByMajorWins = wrestlers_with_same_points.select{|w| w.major_wins.select{|m| m.bracket_position == "Pool"}.size == mostMajorWins}
		if mostMajorWins > 0
			addPointsToWrestlersAhead(wrestlersSortedByMajorWins.first)
			wrestlersSortedByMajorWins.each do |wr|
				wr.pool_placement_tiebreaker = "Most Majors"
				addPoints(wr)	
			end	
		end
	end
	
	def coinFlip(wrestlers_with_same_points)
		wrestler = wrestlers_with_same_points.sample
		wrestler.pool_placement_tiebreaker = "Coin Flip"
		addPointsToWrestlersAhead(wrestler)
	    addPoints(wrestler)
	end
end
