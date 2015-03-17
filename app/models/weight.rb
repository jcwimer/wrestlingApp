class Weight < ActiveRecord::Base
	belongs_to :tournament
	has_many :wrestlers, dependent: :destroy

	attr_accessor :pools, :bracket_size, :bracket_type

	def pools
		@wrestlers = self.wrestlers
		if @wrestlers.size <= 6
			self.pools = 1
		elsif  (@wrestlers.size > 6) && (@wrestlers.size <= 10)
			self.pools = 2
		elsif (@wrestlers.size > 10) && (@wrestlers.size <= 16)
			self.pools = 4
		end
	end

	def returnPoolNumber(wrestler)
		if self.pools == 4
			@wrestlers = fourPoolNumbers(self.wrestlers)
		elsif self.pools == 2
			@wrestlers = twoPoolNumbers(self.wrestlers)
		elsif self.pools == 1
			@wrestlers = onePoolNumbers(self.wrestlers)
		end
		@wrestler = @wrestlers.select{|w| w.id == wrestler.id}.first
		return @wrestler.poolNumber
	end

	def fourPoolNumbers(wrestlers)
		@pool = 1
		wrestlers.sort_by{|x|[x.original_seed]}.reverse.each do |w|
			if w.original_seed == 3
				w.poolNumber = 3
			elsif w.original_seed == 4
				w.poolNumber = 4
			elsif w.original_seed == 1
				w.poolNumber = 1
			elsif w.original_seed == 2
				w.poolNumber = 2
			else
				w.poolNumber = @pool
			end
			if @pool < 4
				@pool = @pool + 1
			else
				@pool =1
			end
		end
		return wrestlers
	end

	def onePoolNumbers(wrestlers)
		wrestlers.sort_by{|x|[x.original_seed]}.each do |w|
			w.poolNumber = 1
		end
		return wrestlers

	end


	def twoPoolNumbers(wrestlers)		
		pool = 1
		wrestlers.sort_by{|x|[x.original_seed]}.reverse.each do |w|
			if w.original_seed == 1
				w.poolNumber = 1
			elsif w.original_seed == 2
				w.poolNumber = 2
			elsif w.original_seed == 3
				w.poolNumber = 2
			elsif w.original_seed == 4
				w.poolNumber = 1
			else
				w.poolNumber = pool
			end
			if pool < 2
				pool = pool + 1
			else
				pool =1
			end
		end
		return wrestlers
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
		@wrestlers = self.wrestlers
		if self.pools == 1
			@pool = Pool.new
			@matches = @pool.generatePools(1,@wrestlers,self,self.tournament_id,matches)
		elsif self.pools == 2
			@pool = Pool.new
			@matches = @pool.generatePools(2,@wrestlers,self,self.tournament_id,matches)
		elsif self.pools == 4
			@pool = Pool.new
			@matches = @pool.generatePools(4,@wrestlers,self,self.tournament_id,matches)
		end
		return @matches
	end
	
end
