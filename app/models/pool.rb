class Pool
	def onePool(wrestlers,weight_id,tournament)
		wrestlers.each do |w|
			w.isWrestlingThisRound?(1)
		end
		
	end


	def twoPools(wrestlers)

	end


	def fourPools(wrestlers)

	end



	def createMatch(w1,w2,round,tournament)

		@match = Match.new
		@match.r_id = w1
		@match.g_id = w2
		@match.round = round
		@match.tournament_id = tournament
		@match.save
	end

end