class Tournament < ActiveRecord::Base
	has_many :schools, dependent: :destroy
	has_many :weights, dependent: :destroy
	has_many :matches, dependent: :destroy
	has_many :mats, dependent: :destroy	
	attr_accessor :upcomingMatches, :unfinishedMatches
	serialize :matchups_array

	def unfinishedMatches
		
	end

	def upcomingMatches
		if self.matchups_array?
			return matchupHashesToObjects(self.matchups_array)
		else
		    return generateMatchups
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
	    self.matchups_array = matchupObjectsToHash(@upcomingMatches)
	    self.save
	    return @upcomingMatches
	end

	def assignBouts(matches)
		@bouts = Bout.new
		@matches = @bouts.assignBouts(matches)
		return @matches
	end
	
	
	def matchupObjectsToHash(matches)
		array_of_hashes = []
		matches.each do |m|
			@matchHash = Hash.new
			@matchHash["w1"] = m.w1
			@matchHash["w2"] = m.w2
			@matchHash["round"] = m.round
			@matchHash["weight_id"] = m.weight_id
			@matchHash["boutNumber"] = m.boutNumber
			@matchHash["w1_name"] = m.w1_name
			@matchHash["w2_name"] = m.w2_name
			@matchHash["bracket_position"] = m.bracket_position
			@matchHash["bracket_position_number"] = m.bracket_position_number
			array_of_hashes << @matchHash
		end
		return array_of_hashes
	end
	
	def matchupHashesToObjects(matches)
		array_of_objects = []
		matches.each do |m|
			@match = Matchup.new
			@match.w1 = m["w1"]
			@match.w2 = m["w2"]
			@match.round = m["round"]
			@match.weight_id = m["weight_id"]
			@match.boutNumber = m["boutNumber"]
			@match.w1_name = m["w1_name"]
			@match.w2_name = m["w2_name"]
			@match.bracket_position = m["bracket_position"]
			@match.bracket_position_number = m["bracket_position_number"]
			array_of_objects << @match
		end
		return array_of_objects
	end

end



