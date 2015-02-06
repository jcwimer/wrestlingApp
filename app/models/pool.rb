class Pool
	def onePool(wrestlers,weight_id,tournament)
		wrestlers.each do |w|
			w.poolNumber = 1
			w.save
		end
		roundRobin(1,tournament,weight_id)
	end


	def twoPools(wrestlers,weight_id,tournament)
		#wrestlers.sort_by{|x|[x.original_seed]}
		
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
		#wrestlers.sort_by{|x|[x.original_seed]}
		
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

	def roundRobin(pool,tournament_id,weight_id)
		@wrestlers = Wrestler.where(weight_id: weight_id, poolNumber: pool).to_a
		@poolMatches = RoundRobinTournament.schedule(@wrestlers)
		@poolMatches.each_with_index do |b,index|
			@bout = b.map
			@bout.each do |b|
				if b[0] != nil and b[1] != nil
					# puts "Start Map Here"
					# puts b[0].name
					# puts " vs " 
					# puts b[1].name
					# puts "Round " 
					# puts index + 1
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

	# def roundRobin(pool,tournament,weight_id)
	# 	@wrestlers = Wrestler.where(weight_id: weight_id, poolNumber: pool)
	# 	@wrestlers.sort_by{|x|[x.original_seed]}.to_a
	# 	@wrestlers.each_with_index do |w,index|
	# 		next_guy_index = index+1
	# 		while index < @wrestlers.length && next_guy_index < @wrestlers.length
	# 			other_guy = @wrestlers[next_guy_index]
	# 			createMatch(w.id,other_guy.id,tournament)
	# 			index += 1
	# 			next_guy_index += 1
	# 		end
	# 	end
	# end


	# def createMatch(w1,w2,tournament)
	# 	@match = Match.new
	# 	@match.r_id = w1
	# 	@match.g_id = w2
	# 	@match.tournament_id = tournament
	# 	@match.save
	# end

end