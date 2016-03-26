class Pool
	def initialize(weight)
		@weight = weight
		@tournament = @weight.tournament
		@pool = 1
	end

	def generatePools
		pools = @weight.pools
		while @pool <= pools
			roundRobin
			@pool += 1
		end
	end

	def roundRobin
		wrestlers = @weight.wrestlersForPool(@pool)
		poolMatches = RoundRobinTournament.schedule(wrestlers).reverse
		poolMatches.each_with_index do |b, index|
			round = index + 1
			bouts = b.map
			bouts.each do |bout|
				if bout[0] != nil and bout[1] != nil
					@tournament.matches.create(
						w1: bout[0].id,
						w2: bout[1].id,
						weight_id: @weight.id,
						bracket_position: "Pool",
						round: round)
				end
			end
		end
	end
end
