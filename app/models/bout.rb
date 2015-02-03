class Bout
	def assignBouts(tournament_id)
		@round = 1
		until matchesByRound(@round, tournament_id).blank? do
				@matches = matchesByRound(@round, tournament_id)
				giveBout(@matches)
				@round += 1
		end
	end

	def matchesByRound(round, tournament_id)
		@matches = Match.where(tournament_id: tournament_id, round: round)
		return @matches
	end

	def giveBout(matches)
		@matches = matches.sort_by{|x|[x.weight_max]}
		@matches.each_with_index do |m, i|
			bout = m.round * 100 + i
			m.boutNumber = bout
			m.save
		end
	end
end