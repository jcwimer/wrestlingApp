class Weight < ActiveRecord::Base
	belongs_to :tournament
	has_many :wrestlers, dependent: :destroy

	attr_accessor :pools, :bracket_size

	def generatePool
		@wrestlers = Wrestler.where(weight_id: self.id)
		@wrestlers.sort_by{|x|[x.original_seed]}
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

	
end
