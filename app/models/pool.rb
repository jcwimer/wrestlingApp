class Pool
	def createPool(tournament)
		@weights = Weight.where(tournament_id: tournament)
		@weights.each do |weight|
			roundRobin(weight,tournament)
		end
	end

	def createBout(wrestler,tournament)
		@bout = Bout.new
		@bout.w1 = wrestler.id 
		@bout.tournament_id = tournament
	end

	def roundRobin(weight,tournament)
		@wrestlers = Wrestler.where(weight_id: weight)
		@wrestlers.each do |wrestler|
			createBout(wrestler,tournament)
		end
	end

	def self.all
    	ObjectSpace.each_object(self).to_a
  	end
  	
  	def self.count
    	all.count
  	end

end