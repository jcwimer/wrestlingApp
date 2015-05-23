class Pool
	def generatePools(weight, tournament)
		matches = []
		@pools = weight.pools
		@pool = 1
		while @pool <= @pools
			matches += roundRobin(weight.wrestlers, weight, tournament)
			@pool += 1
		end
		return matches
	end

	def roundRobin(wrestlers,weight,tournament)
		matches = []
		@wrestlers = wrestlers.select{|w| w.generatePoolNumber == @pool}.to_a
		@poolMatches = RoundRobinTournament.schedule(@wrestlers).reverse
		@poolMatches.each_with_index do |b, index|
			round = index + 1
			@bout = b.map
			@bout.each do |bout|
				if bout[0] != nil and bout[1] != nil
					match = Match.new(w1: bout[0].id, w2: bout[1].id, weight_id: weight.id, round: round)
					matches << match
				end
			end
		end
	  matches
	end
end
