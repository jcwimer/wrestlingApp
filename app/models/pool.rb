class Pool
	def onePool(wrestlers,weight,tournament,matches)
		wrestlers.sort_by{|x|[x.original_seed]}.each do |w|
			w.poolNumber = 1
		end
		matches = roundRobin(1,tournament,weight,matches,wrestlers)
		return matches

	end


	def twoPools(wrestlers,weight,tournament,matches)		
		pool = 1
		wrestlers.sort_by{|x|[x.original_seed]}.reverse.each do |w|
			if w.original_seed == 3
				w.poolNumber = 2
			elsif w.original_seed == 4
				w.poolNumber = 1
			else
				w.poolNumber = pool
			end
			if pool < 2
				pool = pool + 1
			else
				pool =1
			end
		end
		matches = roundRobin(1,tournament,weight,matches,wrestlers)
		matches = roundRobin(2,tournament,weight,matches,wrestlers)
		return matches
	end


	def fourPools(wrestlers,weight,tournament,matches)
		@pool = 1
		wrestlers.sort_by{|x|[x.original_seed]}.reverse.each do |w|
			if w.original_seed == 3
				w.poolNumber = 3
			elsif w.original_seed == 4
				w.poolNumber = 4
			elsif w.original_seed == 1
				w.poolNumber = 1
			elsif w.original_seed == 2
				w.poolNumber = 2
			else
				w.poolNumber = @pool
			end
			if @pool < 4
				@pool = @pool + 1
			else
				@pool =1
			end
		end
		matches = roundRobin(1,tournament,weight,matches,wrestlers)
		matches = roundRobin(2,tournament,weight,matches,wrestlers)
		matches = roundRobin(3,tournament,weight,matches,wrestlers)
		matches = roundRobin(4,tournament,weight,matches,wrestlers)
		return matches
	end

	def roundRobin(pool,tournament_id,weight,matches,wrestlers)
		@wrestlers = wrestlers.to_a
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