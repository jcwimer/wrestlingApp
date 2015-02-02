class Tournament < ActiveRecord::Base
	has_many :schools, dependent: :destroy
	has_many :weights, dependent: :destroy
	has_many :matches, dependent: :destroy
	has_many :mats, dependent: :destroy	

	def generateMatches
		destroyAllMatches
	    self.weights.each do |weight|
	    	puts weight.inspect
	    	weight.generatePool
	    end
	    assignRound
	end

	def destroyAllMatches
		@matches_all = Match.where(tournament_id: self.id)
	    @matches_all.each do |match|
	    		match.destroy
	    end
	end

	def assignRound
		@matches = Match.where(tournament_id: self.id)
		@matches.each do |match|
			@round = 1
			@w1 = Wrestler.find(match.r_id)
			@w2 = Wrestler.find(match.g_id)
			checkRound(@w1,@w2,@round)
			while checkRound(@w1,@w2,@round) == false
				@round = @round + 1
			end
			match.round = @round
			match.save
		end
	end

	def checkRound(w1,w2,round)
		if w1.isWrestlingThisRound(round) == true or
		 w2.isWrestlingThisRound(round) == true
			puts "They wrestle this round"
			return false
		else
			puts "They do not wrestle this round"
			return true
		end
	end
end

#@weights.sort_by{|x|[x.max]}


