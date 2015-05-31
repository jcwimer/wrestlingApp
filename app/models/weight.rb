class Weight < ActiveRecord::Base
	belongs_to :tournament
	has_many :wrestlers, dependent: :destroy
	has_many :matches, dependent: :destroy

	attr_accessor :pools

	HS_WEIGHT_CLASSES = [106,113,120,132,138,145,152,160,170,182,195,220,285]

	before_save do
		tournament.destroyAllMatches
	end

	def wrestlers_for_pool(pool)
		wrestlers.select{|w| w.generatePoolNumber == pool}.to_a
	end

	def pools
		if wrestlers.size <= 6
			return 1
		elsif  wrestlers.size.between?(7, 10)
			return 2
		elsif  wrestlers.size.between?(11, 16)
			return 4
		end
		raise "Unexpected pool size"
	end

	def returnPoolNumber(wrestler)
		if pools == 4
			wr = fourPoolNumbers()
		elsif pools == 2
			wr = twoPoolNumbers()
		elsif pools == 1
			wr = onePoolNumbers()
		end
		target = wr.detect {|w| w.id == wrestler.id}
		return target.poolNumber
	end

	def onePoolNumbers()
		return wrestlers.sort_by{|x|[x.original_seed]}.each do |w|
			w.poolNumber = 1
		end
	end

	TWO_POOL_CONVERSION = { 1 => 1, 2 => 2, 3 => 2, 4 => 1 }

	def twoPoolNumbers()
		wrestlers.sort_by{|x|[x.original_seed]}.reverse.each_with_index do |w, i|
			if w.original_seed && w.original_seed.between?(1, 4)
				w.poolNumber = TWO_POOL_CONVERSION[w.original_seed]
			else
				w.poolNumber = (i % 2) + 1
			end
		end
		return wrestlers
	end

	def fourPoolNumbers()
		return wrestlers.order(original_seed: :desc).each_with_index do |w, i|
      if w.original_seed && w.original_seed.between?(1, 4)
			  w.poolNumber = w.original_seed
			else
				w.poolNumber = (i % 4) + 1
			end
		end
	end

	def bracket_size
		wrestlers.size
	end

	def pool_bracket_type
		return "" if bracket_size < 7
		return "twoPoolsToSemi" if bracket_size.between?(7, 8)
		return "twoPoolsToFinal" if bracket_size.between?(9, 10)
		return "fourPoolsToQuarter" if bracket_size.between?(11, 12)
		return "fourPoolsToSemi" if bracket_size.between?(13, 16)
		raise "invalid pool bracket size"
	end

	def poolRounds()
		poolMatch = matches.where(bracket_position: nil).order(:round).last
		return poolMatch.round if poolMatch
		0
	end

	def totalRounds()
		matches.maximum(:round)
	end

end
