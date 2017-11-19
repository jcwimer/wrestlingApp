class GeneratePoolNumbers
	def initialize( weight )
      @weight = weight
    end

    def savePoolNumbers
		if @weight.pools == 4
			saveFourPoolNumbers(@weight.wrestlersWithoutPool)
		elsif @weight.pools == 2
			saveTwoPoolNumbers(@weight.wrestlersWithoutPool)
		elsif @weight.pools == 1
			saveOnePoolNumbers(@weight.wrestlersWithoutPool)
		end
	end

    def saveOnePoolNumbers(poolWrestlers)
		poolWrestlers.sort_by{|x| x.seed }.each do |w|
			w.pool = 1
			w.save
		end
	end


	def saveTwoPoolNumbers(poolWrestlers)
		pool = 1
		poolWrestlers.sort_by{|x| x.seed }.reverse.each do |w|
			if w.seed == 1
				w.pool = 1
			elsif w.seed == 2
				w.pool = 2
			elsif w.seed == 3
				w.pool = 2
			elsif w.seed == 4
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
		poolWrestlers.sort_by{|x| x.seed }.reverse.each do |w|
			if w.seed == 1
				w.pool = 1
			elsif w.seed == 2
				w.pool = 2
			elsif w.seed == 3
				w.pool = 3
			elsif w.seed == 4
				w.pool = 4
			elsif w.seed == 8
				w.pool = 1
			elsif w.seed == 7
				w.pool = 2
			elsif w.seed == 6
				w.pool = 3
			elsif w.seed == 5
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