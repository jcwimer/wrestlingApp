class Pool
	def onePool(wrestlers,weight_id,tournament)
		wrestlers.each do |w|
			w.poolNumber = 1
			w.save
		end
		roundRobin(1,tournament,weight_id)
	end


	def twoPools(wrestlers,weight_id,tournament)
		wrestlers.sort_by{|x|[x.original_seed]}
		wrestlers.to_a
		pool = 1
		wrestlers.each do |w|
			w.poolNumber = pool
			w.save
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
		wrestlers.sort_by{|x|[x.original_seed]}
		wrestlers.to_a
		pool = 1
		wrestlers.each do |w|
			w.poolNumber = pool
			w.save
			if pool < 4
				pool = pool + 1
			else
				pool =1
			end
		end
		roundRobin(1,tournament,weight_id)
		roundRobin(2,tournament,weight_id)
		roundRobin(3,tournament,weight_id)
		roundRobin(4,tournament,weight_id)
	end

	def roundRobin(pool,tournament,weight_id)
		@wrestlers = Wrestler.where(weight_id: weight_id, poolNumber: pool)
		@wrestlers.sort_by{|x|[x.original_seed]}.to_a
		@wrestlers.each_with_index do |w,index|
			next_guy_index = index+1
			while index < @wrestlers.length && next_guy_index < @wrestlers.length
				other_guy = @wrestlers[next_guy_index]
				createMatch(w.id,other_guy.id,tournament)
				index += 1
				next_guy_index += 1
			end
		end
	end


	def createMatch(w1,w2,tournament)
		@match = Match.new
		@match.r_id = w1
		@match.g_id = w2
		@match.tournament_id = tournament
		@match.save
	end

end