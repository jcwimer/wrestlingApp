class Weight < ActiveRecord::Base
	belongs_to :tournament
	has_many :wrestlers, dependent: :destroy
	has_many :matches, dependent: :destroy

	attr_accessor :pools

	HS_WEIGHT_CLASSES = [106,113,120,132,138,145,152,160,170,182,195,220,285]

	before_save do
		self.tournament.destroyAllMatches
	end

	def wrestlers_for_pool(pool)
		wrestlers.select{|w| w.generatePoolNumber == pool}.to_a
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

	def fourPoolNumbers(wrestlers)
		pool = 1
		wrestlers.sort_by{|x|[x.original_seed]}.reverse.each do |w|
			if w.original_seed == 1
				w.poolNumber = 1
			elsif w.original_seed == 2
				w.poolNumber = 2
			elsif w.original_seed == 3
				w.poolNumber = 3
			elsif w.original_seed == 4
				w.poolNumber = 4
			else
				w.poolNumber = pool
			end
			if pool < 4
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
		@poolMatches = @matchups.select{|m| m.bracket_position == nil}
		return @poolMatches.sort_by{|m| m.round}.last.round
	end

	def totalRounds(matches)
		@matchups = matches.select{|m| m.weight_id == self.id}
		@lastRound = matches.sort_by{|m| m.round}.last.round
		@count = 0
		@round =1
		until @round > @lastRound do
			if @matchups.select{|m| m.round == @round}
				@count = @count + 1
			end
			@round = @round + 1
		end
		return @count
	end

end
