class Boutgen
	def matchesByRound(round, matches)
		@matches = matches.select {|m| m.round == round}
		return @matches
	end

	def giveBout(matches)
		@matches = matches.sort_by{|x|[x.weight_max]}
		@matches.each_with_index do |m, i|
			@bout = m.round * 1000 + i
			m.boutNumber = @bout
		end
		return @matches
	end

	def assignBouts(matches,weights)
		@round = 1
		until matchesByRound(@round, matches).blank? do
				@matches = matchesByRound(@round, matches)
				giveBout(@matches)
				@round += 1
		end
		return matches
	end


end