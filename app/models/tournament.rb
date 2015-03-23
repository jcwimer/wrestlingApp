class Tournament < ActiveRecord::Base
	has_many :schools, dependent: :destroy
	has_many :weights, dependent: :destroy
	has_many :matches, dependent: :destroy
	has_many :mats, dependent: :destroy	
	attr_accessor :upcomingMatches, :unfinishedMatches

	def unfinishedMatches
		
	end

	def upcomingMatches
		@matches = []
		self.weights.sort_by{|x|[x.max]}.each do |weight|
	    	@upcomingMatches = weight.generateMatchups(@matches)
	    end
	    @upcomingMatches = assignBouts(@upcomingMatches)
	    return @upcomingMatches
	end


	def destroyAllMatches
		@matches_all = Match.where(tournament_id: self.id)
	    @matches_all.each do |match|
	    		match.destroy
	    end
	end



	def assignBouts(matches)
		@bouts = Bout.new
		@matches = @bouts.assignBouts(matches)
		return @matches
	end

end



