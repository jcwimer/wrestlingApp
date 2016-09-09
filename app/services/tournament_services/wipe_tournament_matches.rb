class WipeTournamentMatches
    
    def initialize( tournament )
      @tournament = tournament
    end
    
    def setUpMatchGeneration
        wipeMatches
        resetSchoolScores
    end
    
    def wipeWeightMatches(weight)
       weight.matches.destroy_all 
    end
    
    def wipeMatches
       @tournament.matches.destroy_all
    end
    
    def resetSchoolScores
		@tournament.schools.update_all("score = 0.0")
	end
end