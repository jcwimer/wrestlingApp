class Pool
	def generatePools(pools,wrestlers,weight,tournament,matches)
		@pools = pools
		@pool = 1
		while @pool <= @pools
			matches = roundRobin(@pool,wrestlers,weight,tournament,matches)
			@pool = @pool +1
		end
		return matches
	end

	def roundRobin(pool,wrestlers,weight,tournament,matches)
		@wrestlers = wrestlers.select{|w| w.generatePoolNumber == pool}.to_a
		@poolMatches = RoundRobinTournament.schedule(@wrestlers).reverse
		@poolMatches.each_with_index do |b,index|
			@bout = b.map
			@bout.each do |b|
				if b[0] != nil and b[1] != nil
					@match = Matchup.new
					@match.w1 = b[0].id
					@match.w1_name = b[0].name
					@match.w2 = b[1].id
					@match.w2_name = b[1].name
					@match.weight_id = weight.id
					@match.round = index + 1
					matches << @match
				end
			end
		end
	return matches
	end
end