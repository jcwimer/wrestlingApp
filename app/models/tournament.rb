class Tournament < ActiveRecord::Base
	has_many :schools, dependent: :destroy
	has_many :weights, dependent: :destroy
	has_many :matches, dependent: :destroy
	has_many :mats, dependent: :destroy	
	attr_accessor :upcomingMatches

	def upcomingMatches
		@matches = Match.where(tournament_id: self.id)
		@matches.sort_by{|x|[x.boutNumber]}
		# @matches.sort_by{|x|[x.round,x.weight.max]}
	end


	def generateMatches
		destroyAllMatches
	    self.weights.each do |weight|
	    	weight.generatePool
	    end
	    assignRound
	    assignBouts
	end

	def destroyAllMatches
		@matches_all = Match.where(tournament_id: self.id)
	    @matches_all.each do |match|
	    		match.destroy
	    end
	end

	def assignRound
		@matches = Match.where(tournament_id: self.id)
		@matches.sort_by{|x|[x.id]}
		@matches.each do |match|
			@round = 1
			@w1 = Wrestler.find(match.r_id)
			@w2 = Wrestler.find(match.g_id)
			until wrestlingThisRound(@w1,@w2,@round) == false do
				@round += 1
			end
			match.round = @round
			match.save
		end
	end

	def assignBouts
		@bouts = Bout.new
		@bouts.assignBouts(self.id)
	end

	def wrestlingThisRound(w1,w2,round)
		if w1.isWrestlingThisRound(round) == true or
		 w2.isWrestlingThisRound(round) == true
			return true
		else
			return false
		end
	end
end



