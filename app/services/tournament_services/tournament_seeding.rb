class TournamentSeeding
    def initialize( tournament )
      @tournament = tournament
    end
    
    def setSeeds
        @tournament.weights.each do |w|
            resetAllSeeds(w)
            setOriginalSeeds(w)
            randomSeeding(w)
        end
    end
    
    def randomSeeding(weight)
		wrestlerWithSeeds = weight.wrestlers.select{|w| w.original_seed != nil }.sort_by{|w| w.original_seed}
		if wrestlerWithSeeds.size > 0
			highestSeed = wrestlerWithSeeds.last.bracket_line
			seed = highestSeed + 1
		else
			seed = 1
		end
		wrestlersWithoutSeed = weight.wrestlers.select{|w| w.original_seed == nil }
		wrestlersWithoutSeed.shuffle.each do |w|
			w.bracket_line = seed
			w.save
			seed += 1
		end
	end
	
	def setOriginalSeeds(weight)
		wrestlerWithSeeds = weight.wrestlers.select{|w| w.original_seed != nil }
		wrestlerWithSeeds.each do |w|
			w.bracket_line = w.original_seed
			w.save
		end
	end
	
	def resetAllSeeds(weight)
		weight.wrestlers.each do |w|
			w.bracket_line = nil
			w.save
		end
	end
end