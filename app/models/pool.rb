class Pool
	def onePool(wrestlers,weight_id,tournament)
		wrestlers.sort_by{|x|[x.original_seed]}.each do |w|
			w.poolNumber = 1
			w.save
		end
		roundRobin(1,tournament,weight_id)
	end


	def twoPools(wrestlers,weight_id,tournament)		
		pool = 1
		wrestlers.sort_by{|x|[x.original_seed]}.reverse.each do |w|
			if w.original_seed == 3
				w.poolNumber = 2
				w.save
			elsif w.original_seed == 4
				w.poolNumber = 1
				w.save
			else
				w.poolNumber = pool
				w.save
			end
			if pool < 2
				pool = pool + 1
			else
				pool =1
			end
		end
		roundRobin(1,tournament,weight_id)
		roundRobin(2,tournament,weight_id)
	end


	def fourPools(wrestlers,weight_id,tournament)
		@pool = 1
		wrestlers.sort_by{|x|[x.original_seed]}.reverse.each do |w|
			if w.original_seed == 3
				w.poolNumber = 3
				w.save
			elsif w.original_seed == 4
				w.poolNumber = 4
				w.save
			elsif w.original_seed == 1
				w.poolNumber = 1
				w.save
			elsif w.original_seed == 2
				w.poolNumber = 2
				w.save
			else
				w.poolNumber = @pool
				w.save
			end
			if @pool < 4
				@pool = @pool + 1
			else
				@pool =1
			end
		end
		roundRobin(1,tournament,weight_id)
		roundRobin(2,tournament,weight_id)
		roundRobin(3,tournament,weight_id)
		roundRobin(4,tournament,weight_id)
	end

	def roundRobin(pool,tournament_id,weight_id)
		@wrestlers = Wrestler.where(weight_id: weight_id, poolNumber: pool).to_a
		@poolMatches = RoundRobinTournament.schedule(@wrestlers).reverse
		@poolMatches.each_with_index do |b,index|
			@bout = b.map
			@bout.each do |b|
				if b[0] != nil and b[1] != nil
					@match = Match.new
					@match.r_id = b[0].id
					@match.g_id = b[1].id
					@match.tournament_id = tournament_id
					@match.round = index + 1
					@match.save
				end
			end
		end
	end
end