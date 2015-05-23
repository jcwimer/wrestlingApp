class Pool
	def initialize(weight)
		@weight = weight
		@pool = 1
	end

	def generatePools
		matches = []
		pools = @weight.pools
		while @pool <= pools
			matches += roundRobin()
			@pool += 1
		end
		return matches
	end

	def roundRobin
		matches = []
		wrestlers = @weight.wrestlers.select{|w| w.generatePoolNumber == @pool}.to_a
		poolMatches = RoundRobinTournament.schedule(wrestlers).reverse
		poolMatches.each_with_index do |b, index|
			round = index + 1
			bouts = b.map
			bouts.each do |bout|
				if bout[0] != nil and bout[1] != nil
					match = Match.new(
						w1: bout[0].id,
						w2: bout[1].id,
						weight_id: @weight.id,
						round: round)
					matches << match
				end
			end
		end
	  matches
	end
end
