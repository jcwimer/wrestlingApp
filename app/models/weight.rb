class Weight < ApplicationRecord
	belongs_to :tournament, touch: true
	has_many :wrestlers, dependent: :destroy
	has_many :matches, dependent: :destroy

	attr_accessor :pools
	
	validates :max, presence: true

    # passed via layouts/_tournament-navbar.html.erb
    # tournaments controller does a .split(',') on this string and creates an array via commas
    # tournament model runs the code via method create_pre_defined_weights
	HS_WEIGHT_CLASSES = "106,113,120,126,132,138,144,150,157,165,175,190,215,285"
	HS_GIRLS_WEIGHT_CLASSES = "100,105,110,115,120,125,130,135,140,145,155,170,190,235"
	MS_WEIGHT_CLASSES = "80,86,92,98,104,110,116,122,128,134,142,150,160,172,205,245"
	MS_GIRLS_WEIGHT_CLASSES = "72,80,86,92,98,104,110,116,122,128,134,142,155,170,190,235"
	
	before_destroy do 
		self.tournament.destroy_all_matches
	end

	before_save do
		# self.tournament.destroy_all_matches
	end

	def pools_with_bye
		pool = 1
		pools_with_a_bye = []
		until pool > self.pools do
			if wrestlers_in_pool(pool).first.has_a_pool_bye
              pools_with_a_bye << pool
            end
            pool = pool + 1
		end
		pools_with_a_bye
	end

	def wrestlers_in_pool(pool_number)
		#For some reason this does not work
		# wrestlers.select{|w| w.pool == pool_number}

		#This does...
		weight_wrestlers = Wrestler.where(:weight_id => self.id)
		weight_wrestlers.select{|w| w.pool == pool_number}
	end

	def one_pool_empty
      (1..self.pools).each do |pool|
        if wrestlers_in_pool(pool).size < 1
          return true
        end
      end
      return false
	end
	
	def all_pool_matches_finished(pool)
		wrestlers = wrestlers_in_pool(pool)
		wrestlers.each do |w|
			if w.pool_matches.size != w.finished_pool_matches.size
				return false
			end
   		end
		return true
	end

	def pools
		wrestlers = self.wrestlers
		if wrestlers.size <= 6
			self.pools = 1
		elsif  (wrestlers.size > 6) && (wrestlers.size <= 10)
			self.pools = 2
		elsif (wrestlers.size > 10) && (wrestlers.size <= 16)
			self.pools = 4
		elsif (wrestlers.size > 16) && (wrestlers.size <= 24)
			self.pools = 8
		end
	end
	
	def pool_wrestlers_sorted_by_bracket_line(pool)
		# wrestlers_in_pool(pool).sort_by{|w| [w.original_seed ? 0 : 1, w.original_seed || 0]}	
		return wrestlers_in_pool(pool).sort_by{|w|w.bracket_line}
	end
	
	
	def swap_wrestlers_bracket_lines(wrestler1_id,wrestler2_id)
		SwapWrestlers.new.swap_wrestlers_bracket_lines(wrestler1_id,wrestler2_id)
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
	    elsif self.wrestlers.size > 16 && self.wrestlers.size <= 24
			return "eightPoolsToQuarter"
		elsif self.wrestlers.size <= 6
			return "onePool"
		end
	end

	def pool_full(pool)
      current_wrestlers = wrestlers_in_pool(pool)
      if self.pool_bracket_type == "twoPoolsToSemi"
      	max = 4
      elsif self.pool_bracket_type == "twoPoolsToFinal"
      	max = 5
      elsif self.pool_bracket_type == "fourPoolsToQuarter"
      	max = 3
      elsif self.pool_bracket_type == "fourPoolsToSemi"
      	max = 4
      elsif self.pool_bracket_type == "eightPoolsToQuarter"
      	max = 3
      end
      if max == current_wrestlers
      	true
      else
      	false
      end
	end

	def pool_rounds(matches)
		matchups = matches.select{|m| m.weight_id == self.id}
		pool_matches = matchups.select{|m| m.bracket_position == "Pool"}
		return pool_matches.sort_by{|m| m.round}.last.round
	end

	def total_rounds(matches)
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
	
	def pool_placement_order(pool)
		#PoolOrder.new(wrestlers_in_pool(pool)).getPoolOrder
	end

	def wrestlers_without_pool_assignment
		wrestlers.select{|w| w.pool == nil}
	end

	def calculate_bracket_size
		num_wrestlers = wrestlers.reload.size
		return nil if num_wrestlers <= 0 # Handle invalid input
	  
		# Find the smallest power of 2 greater than or equal to num_wrestlers
		2**Math.log2(num_wrestlers).ceil
	end

	def highest_bracket_round
		bracket_matches_sorted_by_round_descending =  matches.select{|m| m.bracket_position.include? "Bracket"}.sort_by{|m| m.round}.reverse
		if bracket_matches_sorted_by_round_descending.size > 0
			return bracket_matches_sorted_by_round_descending.first.round
		else
			return nil
		end
	end

	def lowest_bracket_round
		bracket_matches_sorted_by_round_ascending =  matches.select{|m| m.bracket_position.include? "Bracket"}.sort_by{|m| m.round}
		if bracket_matches_sorted_by_round_ascending.size > 0
			return bracket_matches_sorted_by_round_ascending.first.round
		else
			return nil
		end
	end

	def highest_conso_round
		conso_matches_sorted_by_round_descending =  matches.select{|m| m.bracket_position.include? "Conso"}.sort_by{|m| m.round}.reverse
		if conso_matches_sorted_by_round_descending.size > 0
			return conso_matches_sorted_by_round_descending.first.round
		else
			return nil
		end
	end

	def lowest_conso_round
		conso_matches_sorted_by_round_ascending =  matches.select{|m| m.bracket_position.include? "Conso"}.sort_by{|m| m.round}
		if conso_matches_sorted_by_round_ascending.size > 0
			return conso_matches_sorted_by_round_ascending.first.round
		else
			return nil
		end
	end
end
