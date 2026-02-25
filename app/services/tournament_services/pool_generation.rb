class PoolGeneration
	def initialize(weight, wrestlers: nil)
		@weight = weight
		@tournament = @weight.tournament
		@pool = 1
    @wrestlers = wrestlers
	end

	def generatePools
		GeneratePoolNumbers.new(@weight).savePoolNumbers(wrestlers: wrestlers_for_weight, persist: false)
		rows = []
		pools = @weight.pools
		while @pool <= pools
			rows.concat(roundRobin)
			@pool += 1
		end
    rows
	end		

	def roundRobin
		rows = []
		wrestlers = wrestlers_for_weight.select { |w| w.pool == @pool }
		pool_matches = RoundRobinTournament.schedule(wrestlers).reverse
		pool_matches.each_with_index do |b, index|
			round = index + 1
			bouts = b.map
			bouts.each do |bout|
				if bout[0] != nil and bout[1] != nil
					rows << {
						w1: bout[0].id,
						w2: bout[1].id,
						tournament_id: @tournament.id,
						weight_id: @weight.id,
						bracket_position: "Pool",
						round: round
					}
				end
			end
		end
		rows
	end

  def wrestlers_for_weight
    @wrestlers || @weight.wrestlers.to_a
  end
end
