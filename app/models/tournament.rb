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
	end

	def destroyAllMatches
		@matches_all = Match.where(tournament_id: self.id)
	    @matches_all.each do |match|
	    		match.destroy
	    end
	end

end
