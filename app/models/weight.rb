class Weight < ActiveRecord::Base
	belongs_to :tournament
	has_many :wrestlers, dependent: :destroy
	has_many :matches, dependent: :destroy

	attr_accessor :pools
	
	validates :max, presence: true

	HS_WEIGHT_CLASSES = [106,113,120,126,132,138,145,152,160,170,182,195,220,285]
	
	before_destroy do 
		self.tournament.destroyAllMatches
	end

	before_save do
		self.tournament.destroyAllMatches
	end

	def wrestlersForPool(pool)
		self.wrestlers.select{|w| w.generatePoolNumber == pool}
	end
	
	def allPoolMatchesFinished(pool)
		@wrestlers = wrestlersForPool(pool)
		@wrestlers.each do |w|
			if w.poolMatches.size != w.finishedPoolMatches.size
				return false
			end
   		end
		return true
	end

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
	
	def poolSeedOrder(pool)
		wrestlersForPool(pool).sort_by{|w| [w.original_seed ? 0 : 1, w.original_seed || 0]}	
	end
	
	def setOriginalSeedsToWrestleLastPoolRound
		pool = 1
		until pool > self.pools
			wrestler1 = poolSeedOrder(pool).first
			wrestler2 = poolSeedOrder(pool).second
			match = wrestler1.poolMatches.sort_by{|m| m.round}.last
			if match.w1 != wrestler2.id or match.w2 != wrestler2.id
				if match.w1 == wrestler1.id
					swapWrestlers(match.w2,wrestler2.id)
				elsif match.w2 == wrestler1.id
					swapWrestlers(match.w1,wrestler2.id)
				end
			end
		    pool += 1
		end
	end
	
	def swapWrestlers(wrestler1_id,wrestler2_id)
		self.tournament.swapWrestlers(wrestler1_id,wrestler2_id)	
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

	def onePoolNumbers(poolWrestlers)
		poolWrestlers.sort_by{|x| x.seed }.each do |w|
			w.poolNumber = 1
		end
		return poolWrestlers
	end


	def twoPoolNumbers(poolWrestlers)
		pool = 1
		poolWrestlers.sort_by{|x| x.seed }.reverse.each do |w|
			if w.seed == 1
				w.poolNumber = 1
			elsif w.seed == 2
				w.poolNumber = 2
			elsif w.seed == 3
				w.poolNumber = 2
			elsif w.seed == 4
				w.poolNumber = 1
			else
				w.poolNumber = pool
			end
			if pool < 2
				pool = pool + 1
			else
				pool = 1
			end
		end
		return poolWrestlers
	end

	def fourPoolNumbers(poolWrestlers)
		pool = 1
		poolWrestlers.sort_by{|x| x.seed }.reverse.each do |w|
			if w.seed == 1
				w.poolNumber = 1
			elsif w.seed == 2
				w.poolNumber = 2
			elsif w.seed == 3
				w.poolNumber = 3
			elsif w.seed == 4
				w.poolNumber = 4
			elsif w.seed == 8
				w.poolNumber = 1
			elsif w.seed == 7
				w.poolNumber = 2
			elsif w.seed == 6
				w.poolNumber = 3
			elsif w.seed == 5
				w.poolNumber = 4
			else
				w.poolNumber = pool
			end
			if pool < 4
				pool = pool + 1
			else
				pool = 1
			end
		end
		return poolWrestlers
	end

	def bracket_size
		wrestlers.size
	end

	def pool_bracket_type
		if self.wrestlers.size > 6 && self.wrestlers.size <= 8
			return "twoPoolsToSemi"
		elsif self.wrestlers.size > 8 && self.wrestlers.size <= 10
			return "twoPoolsToFinal"
		elsif self.wrestlers.size == 11 || self.wrestlers.size == 12
			return "fourPoolsToQuarter"
		elsif self.wrestlers.size > 12 && self.wrestlers.size <= 16
			return "fourPoolsToSemi"
		end
	end

	def poolRounds(matches)
		@matchups = matches.select{|m| m.weight_id == self.id}
		@poolMatches = @matchups.select{|m| m.bracket_position == "Pool"}
		return @poolMatches.sort_by{|m| m.round}.last.round
	end

	def totalRounds(matches)
		@matchups = matches.select{|m| m.weight_id == self.id}
		@lastRound = matches.sort_by{|m| m.round}.last.round
		count = 0
		@round =1
		until @round > @lastRound do
			if @matchups.select{|m| m.round == @round}
				count = count + 1
			end
			@round = @round + 1
		end
		return count
	end
	
	def poolOrder(pool)
		PoolOrder.new(wrestlersForPool(pool)).getPoolOrder
	end
	
	def randomSeeding
		wrestlerWithSeeds = self.wrestlers.select{|w| w.original_seed != nil }.sort_by{|w| w.original_seed}
		highestSeed = wrestlerWithSeeds.last.original_seed
		seed = highestSeed + 1
		wrestlersWithoutSeed = self.wrestlers.select{|w| w.original_seed == nil }
		wrestlersWithoutSeed.shuffle.each do |w|
			w.seed = seed
			w.save
			seed += 1
		end
	end
	
	def setSeeds
		resetAllSeeds
		wrestlerWithSeeds = self.wrestlers.select{|w| w.original_seed != nil }.sort_by{|w| w.original_seed}
		wrestlerWithSeeds.each do |w|
			w.seed = w.original_seed
			w.save
		end
		randomSeeding
	end
	
	def resetAllSeeds
		self.wrestlers.each do |w|
			w.seed = nil
			w.save
		end
	end
			
end
