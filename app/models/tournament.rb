class Tournament < ActiveRecord::Base
	has_many :schools, dependent: :destroy
	has_many :weights, dependent: :destroy
	has_many :matches, dependent: :destroy
	has_many :mats, dependent: :destroy	
	has_many :wrestlers, through: :weights

	serialize :matchups_array

	def upcomingMatches
		if self.matches.nil?
			return self.matches
		else
			@matches = generateMatchups
			saveMatchups(@matches)
			return @matches
		end
	end

	def generateMatchups
		@matches = []
		self.weights.map.sort_by{|x|[x.max]}.each do |weight|
    		@matches = weight.generateMatchups(@matches)
	    end
	    @matches = assignBouts(@matches)
		  @matches = Losernamegen.new.assignLoserNames(@matches,self.weights)
	    return @matches
	end

	def assignBouts(matches)
		@bouts = Boutgen.new
		@matches = @bouts.assignBouts(matches,self.weights)
		return @matches
	end
	
	def saveMatchups(matches)
		matches.each do |m|
	    m.save
		end
	end

end



