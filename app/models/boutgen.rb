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
		assignLoserNames(matches,weights)
		return matches
	end

  def assignLoserNames(matches,weights)
		weights.each do |w|
			@matches = matches.select{|m| m.weight_id == w.id}
			if w.pool_bracket_type == "twoPoolsToSemi"
				twoPoolsToSemiLoser(@matches)
			elsif w.pool_bracket_type == "fourPoolsToQuarter"
				fourPoolsToQuarterLoser(@matches)
			elsif w.pool_bracket_type == "fourPoolsToSemi"
				fourPoolsToSemiLoser(@matches)
			end
		end
	end

  def twoPoolsToSemiLoser(matches)
		@match1 = matches.select{|m| m.w1_name == "Winner Pool 1"}.first
		@match2 = matches.select{|m| m.w1_name == "Winner Pool 2"}.first
		@matchChange = matches.select{|m| m.bracket_position == "3/4"}.first
		@matchChange.w1_name = "Loser of #{@match1.boutNumber}"
		@matchChange.w2_name = "Loser of #{@match2.boutNumber}"
	end

  def fourPoolsToQuarterLoser(matches)
		@quarters = matches.select{|m| m.bracket_position == "Quarter"}
		@consoSemis = matches.select{|m| m.bracket_position == "Conso Semis"}
		@semis = matches.select{|m| m.bracket_position == "Semis"}
		@thirdFourth = matches.select{|m| m.bracket_position == "3/4"}.first
		@seventhEighth = matches.select{|m| m.bracket_position == "7/8"}.first
		@consoSemis.each do |match|
			if match.bracket_position_number == 1
				match.w1_name = "Loser of #{@quarters.select{|m| m.bracket_position_number == 1}.first.boutNumber}"
				match.w2_name = "Loser of #{@quarters.select{|m| m.bracket_position_number == 2}.first.boutNumber}"
			elsif match.bracket_position_number == 2
				match.w1_name = "Loser of #{@quarters.select{|m| m.bracket_position_number == 3}.first.boutNumber}"
				match.w2_name = "Loser of #{@quarters.select{|m| m.bracket_position_number == 4}.first.boutNumber}"
			end
		end
		@thirdFourth.w1_name = "Loser of #{@semis.select{|m| m.bracket_position_number == 1}.first.boutNumber}"
		@thirdFourth.w2_name = "Loser of #{@semis.select{|m| m.bracket_position_number == 2}.first.boutNumber}"
		@consoSemis = matches.select{|m| m.bracket_position == "Conso Semis"}
		@seventhEighth.w1_name = "Loser of #{@consoSemis.select{|m| m.bracket_position_number == 1}.first.boutNumber}"
		@seventhEighth.w2_name = "Loser of #{@consoSemis.select{|m| m.bracket_position_number == 2}.first.boutNumber}"
	end

  def fourPoolsToSemiLoser(matches)
		@semis = matches.select{|m| m.bracket_position == "Semis"}
		@thirdFourth = matches.select{|m| m.bracket_position == "3/4"}.first
		@consoSemis = matches.select{|m| m.bracket_position == "Conso Semis"}
		@seventhEighth = matches.select{|m| m.bracket_position == "7/8"}.first
		@thirdFourth.w1_name = "Loser of #{@semis.select{|m| m.bracket_position_number == 1}.first.boutNumber}"
		@thirdFourth.w2_name = "Loser of #{@semis.select{|m| m.bracket_position_number == 2}.first.boutNumber}"
		@seventhEighth.w1_name = "Loser of #{@consoSemis.select{|m| m.bracket_position_number == 1}.first.boutNumber}"
		@seventhEighth.w2_name = "Loser of #{@consoSemis.select{|m| m.bracket_position_number == 2}.first.boutNumber}"
	end
end