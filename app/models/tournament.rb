class Tournament < ActiveRecord::Base
	has_many :schools, dependent: :destroy
	has_many :weights, dependent: :destroy
	has_many :matches, dependent: :destroy
	has_many :mats, dependent: :destroy	
	attr_accessor :upcomingMatches, :unfinishedMatches

	def self.unfinishedMatches
		
	end

	def upcomingMatches
		# @matches = Match.where(tournament_id: self.id)
		# @matches.sort_by{|x|[x.boutNumber]}
		# @matches.sort_by{|x|[x.round,x.weight.max]}
		@matches = []
		self.weights.sort_by{|x|[x.max]}.each do |weight|
	    	@upcomingMatches = weight.generateMatchups(@matches)
	    end
	    return @upcomingMatches
	end


	def generateMatches
		destroyAllMatches
	    self.weights.each do |weight|
	    	weight.generatePool
	    end
	    # assignRound
	    assignBouts
	end
	handle_asynchronously :generateMatches

	def destroyAllMatches
		@matches_all = Match.where(tournament_id: self.id)
	    @matches_all.each do |match|
	    		match.destroy
	    end
	end



	def assignBouts
		@bouts = Bout.new
		@bouts.assignBouts(self.id)
	end

end



