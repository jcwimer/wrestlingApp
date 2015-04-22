class Tournament < ActiveRecord::Base
	has_many :schools, dependent: :destroy
	has_many :weights, dependent: :destroy
	has_many :matches, dependent: :destroy
	has_many :mats, dependent: :destroy	
	has_many :wrestlers, through: :weights

	serialize :matchups_array

	def upcomingMatches
		@matches = generateMatchups
		# if self.matchups_array
		# 	return matchupHashesToObjects(self.matchups_array)
		# else
		# 	@matches = generateMatchups
		#     saveMatchups(@matches)
		#     return @matches
		# end
	end

	def generateMatchups
		@matches = []
		self.weights.map.sort_by{|x|[x.max]}.each do |weight|
    		@matches = weight.generateMatchups(@matches)
	    end
	    @matches = assignBouts(@matches)
	    return @matches
	end

	def assignBouts(matches)
		@bouts = Boutgen.new
		@matches = @bouts.assignBouts(matches,self.weights)
		return @matches
	end
	
	def saveMatchups(matches)
		self.matchups_array = matchupObjectsToHash(matches)
	    self.save	
	end
	
	
	def matchupObjectsToHash(matches)
		array_of_hashes = []
		matches.each do |m|
			@matchHash = m.to_hash
			array_of_hashes << @matchHash
		end
		return array_of_hashes
	end
	
	def matchupHashesToObjects(matches)
		array_of_objects = []
		matches.each do |m|
			@match = Matchup.new
			@match.convert_to_obj(m)
			array_of_objects << @match
		end
		return array_of_objects
	end

end



