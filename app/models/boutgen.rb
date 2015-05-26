class Boutgen

	def matchesByRound(tournament, round)
		tournament.matches.joins(:weight).where(round: round).order("weights.max")
	end

	def assignBouts(tournament)
		bout_counts = Hash.new(0)
		matches = tournament.matches.each do |m|
			m.bout_number = m.round * 1000 + bout_counts[m.round]
			bout_counts[m.round] += 1
			m.save!
		end
	end

end
