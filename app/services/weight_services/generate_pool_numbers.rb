class GeneratePoolNumbers
	def initialize( weight )
      @weight = weight
    end

    def savePoolNumbers
    	@weight.wrestlers.each do |wrestler|
          if wrestler.pool and (wrestler.pool) > (@weight.pools)
          	resetPool
          end
    	end
		if @weight.pools == 4
			saveFourPoolNumbers(@weight.wrestlers_without_pool_assignment)
		elsif @weight.pools == 2
			saveTwoPoolNumbers(@weight.wrestlers_without_pool_assignment)
		elsif @weight.pools == 1
			saveOnePoolNumbers(@weight.wrestlers_without_pool_assignment)
		elsif @weight.pools == 8
			saveEightPoolNumbers(@weight.wrestlers_without_pool_assignment)
		end
		saveRandomPool(@weight.reload.wrestlers_without_pool_assignment)
	end

	def resetPool
      @weight.wrestlers.each do |wrestler|
        wrestler.pool = nil
        wrestler.save
        @weight.reload
      end
	end

	def saveRandomPool(poolWrestlers)
	  pool = 1
      poolWrestlers.sort_by{|x| x.bracket_line }.reverse.each do |wrestler|
        wrestler.pool = pool
        wrestler.save
        if pool < @weight.pools
        	pool = pool + 1
        else
        	pool = 1
        end
      end
	end

    def saveOnePoolNumbers(poolWrestlers)
		poolWrestlers.sort_by{|x| x.bracket_line }.each do |w|
			w.pool = 1
			w.save
		end
	end


	def saveTwoPoolNumbers(poolWrestlers)
		poolWrestlers.sort_by{|x| x.bracket_line }.reverse.each do |w|
			if w.bracket_line == 1
				w.pool = 1
			elsif w.bracket_line == 2
				w.pool = 2
			elsif w.bracket_line == 3
				w.pool = 2
			elsif w.bracket_line == 4
				w.pool = 1
			end
			w.save
		end
	end

	def saveFourPoolNumbers(poolWrestlers)
		poolWrestlers.sort_by{|x| x.bracket_line }.reverse.each do |w|
			if w.bracket_line == 1
				w.pool = 1
			elsif w.bracket_line == 2
				w.pool = 2
			elsif w.bracket_line == 3
				w.pool = 3
			elsif w.bracket_line == 4
				w.pool = 4
			elsif w.bracket_line == 8
				w.pool = 1
			elsif w.bracket_line == 7
				w.pool = 2
			elsif w.bracket_line == 6
				w.pool = 3
			elsif w.bracket_line == 5
				w.pool = 4
			end
			w.save
		end
	end

	def saveEightPoolNumbers(poolWrestlers)
		poolWrestlers.sort_by{|x| x.bracket_line }.reverse.each do |w|
			if w.bracket_line == 1
				w.pool = 1
			elsif w.bracket_line == 2
				w.pool = 2
			elsif w.bracket_line == 3
				w.pool = 3
			elsif w.bracket_line == 4
				w.pool = 4
			elsif w.bracket_line == 5
				w.pool = 5
			elsif w.bracket_line == 6
				w.pool = 6
			elsif w.bracket_line == 7
				w.pool = 7
			elsif w.bracket_line == 8
				w.pool = 8
			end
			w.save
		end
	end
end