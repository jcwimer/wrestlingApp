class Tournament < ActiveRecord::Base
	has_many :schools, dependent: :destroy
	has_many :weights, dependent: :destroy
	has_many :mats, dependent: :destroy
	has_many :wrestlers, through: :weights


	def tournament_types
		["Pool to bracket"]
	end

	def matches
		@matches = Match.where(tournament_id: self.id)
	end

  def createCustomWeights(value)
		self.weights.destroy_all
		if value == 'hs'
			@weights = [106,113,120,132,138,145,152,160,170,182,195,220,285]
		end
		@weights.each do |w|
			newWeight = Weight.new
			newWeight.max = w
			newWeight.tournament_id = self.id
			newWeight.save
		end
	end

	def upcomingMatches
		if matches.nil?
			return matches
		else
			generateMatchups
			return matches
		end
	end

	def generateMatchups
		@matches = Tournamentmatchgen.new.genMatches(self)
	end

	def destroyAllMatches
		matches.destroy_all
	end

end



