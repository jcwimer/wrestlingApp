class Weight < ActiveRecord::Base
	belongs_to :tournament
	has_many :wrestlers, dependent: :destroy

	attr_accessor :pools, :bracket_size, :bracket_type

	def generatePool
		@wrestlers = Wrestler.where(weight_id: self.id)
		#@wrestlers.sort_by{|w| [w.original_seed]}
		if self.pools == 1
			@pool = Pool.new
			@pool.onePool(@wrestlers,self.id,self.tournament_id)
		elsif self.pools == 2
			@pool = Pool.new
			@pool.twoPools(@wrestlers,self.id,self.tournament_id)
		elsif self.pools == 4
			@pool = Pool.new
			@pool.fourPools(@wrestlers,self.id,self.tournament_id)
		end
	end

	def pools
		@wrestlers = Wrestler.where(weight_id: self.id)
		if @wrestlers.size <= 6
			self.pools = 1
		elsif  (@wrestlers.size > 6) && (@wrestlers.size <= 10)
			self.pools = 2
		elsif (@wrestlers.size > 10) && (@wrestlers.size <= 16)
			self.pools = 4
		end
	end

	def bracket_size
		@wrestlers = Wrestler.where(weight_id: self.id)
		return @wrestlers.size
	end

	def pool_bracket_type
		if self.wrestlers.size > 7 && self.wrestlers.size <= 8
			return "twoPoolsToSemi"
		elsif self.wrestlers.size > 8 && self.wrestlers.size <= 10
			return "twoPoolToFinal"			
		elsif self.wrestlers.size == 11
			return "fourPoolsToQuarter"
		elsif self.wrestlers.size > 11 && self.wrestlers.size <= 16
			return "fourPoolsToSemi"			
		end
		self.wrestlers.size 
	end

	def generateMatchups(matches)
		@wrestlers = Wrestler.where(weight_id: self.id)
		#@wrestlers.sort_by{|w| [w.original_seed]}
		if self.pools == 1
			@pool = Pool.new
			@matches = @pool.onePool(@wrestlers,self.id,self.tournament_id,matches)
		elsif self.pools == 2
			@pool = Pool.new
			@matches = @pool.twoPools(@wrestlers,self.id,self.tournament_id,matches)
		elsif self.pools == 4
			@pool = Pool.new
			@matches = @pool.fourPools(@wrestlers,self.id,self.tournament_id,matches)
		end
		return @matches
	end
	
end
