class Tournament < ActiveRecord::Base
	has_many :schools, dependent: :destroy
	has_many :weights, dependent: :destroy
	has_many :matches, dependent: :destroy
	has_many :mats, dependent: :destroy	
	attr_accessor :upcomingMatches, :unfinishedMatches
	serialize :matchups

	def unfinishedMatches
		
	end

	def upcomingMatches
		if self.matchups?
			return self.matchups
		else
			@upcomingMatches = generateMatchups
		    return @upcomingMatches
	    end
	end


	def destroyAllMatches
		@matches_all = Match.where(tournament_id: self.id)
	    @matches_all.each do |match|
	    		match.destroy
	    end
	end

	def generateMatchups
		@matches = []
		self.weights.map.sort_by{|x|[x.max]}.each do |weight|
    		@upcomingMatches = weight.generateMatchups(@matches)
	    end
	    @upcomingMatches = assignBouts(@upcomingMatches)
	    self.matchups = @upcomingMatches
	    self.save
	    return @upcomingMatches
	end

	def assignBouts(matches)
		@bouts = Bout.new
		@matches = @bouts.assignBouts(matches)
		return @matches
	end

end



