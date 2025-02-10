class GeneratePoolNumbers
	def initialize( weight )
      @weight = weight
    end

    def savePoolNumbers
    	@weight.wrestlers.each do |wrestler|
			wrestler.pool = get_wrestler_pool_number(@weight.pools, wrestler.bracket_line)
			wrestler.save
		end
	end

	def get_wrestler_pool_number(number_of_pools, wrestler_seed)
		# Convert seed to zero-based index for easier math
		zero_based = wrestler_seed - 1
	  
		# Determine which "row" we're on (0-based)
		# e.g., with 4 pools:
		#   seeds 1..4 are in row 0,
		#   seeds 5..8 are in row 1,
		#   seeds 9..12 in row 2, etc.
		row = zero_based / number_of_pools
	  
		# Column within that row (also 0-based)
		col = zero_based % number_of_pools
	  
		if row.even?
		  # Row is even => left-to-right
		  # col=0 => pool 1, col=1 => pool 2, etc.
		  pool = col + 1
		else
		  # Row is odd => right-to-left
		  # col=0 => pool number_of_pools, col=1 => pool number_of_pools-1, etc.
		  pool = number_of_pools - col
		end
	  
		pool
	end	  
end