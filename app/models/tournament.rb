class Tournament < ActiveRecord::Base
	has_many :schools, dependent: :destroy
	has_many :weights, dependent: :destroy
	has_many :matches, dependent: :destroy
	has_many :mats, dependent: :destroy	
	has_many :wrestlers, through: :weights
	attr_accessor :upcomingMatches, :unfinishedMatches

	def self.unfinishedMatches
		
	end

	def upcomingMatches
		@matches = []
		@wrestlers = self.wrestlers
		self.weights.sort_by{|x|[x.max]}.each do |weight|
	    	@upcomingMatches = generateMatchups(@matches,@wrestlers,weight)
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

	def generateMatchups(matches,wrestlers,weight)
		@wrestlers = wrestlers.select{|w| w.weight_id == weight.id}
		if weight.pools == 1
			@pool = Pool.new
			@matches = @pool.generatePools(1,@wrestlers,weight,self.id,matches)
		elsif weight.pools == 2
			@pool = Pool.new
			@matches = @pool.generatePools(2,@wrestlers,weight,self.id,matches)
		elsif weight.pools == 4
			@pool = Pool.new
			@matches = @pool.generatePools(4,@wrestlers,weight,self.id,matches)
		end
		return @matches
	end

end



