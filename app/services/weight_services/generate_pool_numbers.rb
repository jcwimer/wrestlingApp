class GeneratePoolNumbers
	def initialize( weight )
      @weight = weight
    end

    def savePoolNumbers
		if @weight.pools == 4
			saveFourPoolNumbers(@weight.wrestlers_without_pool_assignment)
		elsif @weight.pools == 2
			saveTwoPoolNumbers(@weight.wrestlers_without_pool_assignment)
		elsif @weight.pools == 1
			saveOnePoolNumbers(@weight.wrestlers_without_pool_assignment)
		end
	end

    def saveOnePoolNumbers(poolWrestlers)
		poolWrestlers.sort_by{|x| x.bracket_line }.each do |w|
			w.pool = 1
			w.save
		end
	end


	def saveTwoPoolNumbers(poolWrestlers)
		pool = 1
		poolWrestlers.sort_by{|x| x.bracket_line }.reverse.each do |w|
			if w.bracket_line == 1
				w.pool = 1
			elsif w.bracket_line == 2
				w.pool = 2
			elsif w.bracket_line == 3
				w.pool = 2
			elsif w.bracket_line == 4
				w.pool = 1
			else
				w.pool = pool
			end
			if pool < 2
				pool = pool + 1
			else
				pool = 1
			end
			w.save
		end
	end

	def saveFourPoolNumbers(poolWrestlers)
		pool = 1
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
			else
				w.pool = pool
			end
			if pool < 4
				pool = pool + 1
			else
				pool = 1
			end
			w.save
		end
	end
end