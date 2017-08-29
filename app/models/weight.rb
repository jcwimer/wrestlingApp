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
		# self.tournament.destroyAllMatches
	end

	def pools_with_bye
		pool = 1
		pools_with_a_bye = []
		until pool > self.pools do
			if wrestlersForPool(pool).first.hasAPoolBye
              pools_with_a_bye << pool
            end
            pool = pool + 1
		end
		pools_with_a_bye
	end

	def wrestlersForPool(poolNumber)
		#For some reason this does not work
		# wrestlers.select{|w| w.pool == poolNumber}

		#This does...
		weightWrestlers = Wrestler.where(:weight_id => self.id)
		weightWrestlers.select{|w| w.pool == poolNumber}
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
		# wrestlersForPool(pool).sort_by{|w| [w.original_seed ? 0 : 1, w.original_seed || 0]}	
		return wrestlersForPool(pool).sort_by{|w|w.seed}
	end
	
	
	def swapWrestlers(wrestler1_id,wrestler2_id)
		SwapWrestlers.new.swapWrestlers(wrestler1_id,wrestler2_id)
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

	def wrestlersWithoutPool
		wrestlers.select{|w| w.pool == nil}
	end
			
end
