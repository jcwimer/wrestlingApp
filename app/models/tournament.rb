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
			Weight::HS_WEIGHT_CLASSES.each do |w|
				self.weights.create(max: w)
			end
		else
			raise "Unspecified behavior"
		end
	end

	def upcomingMatches
		if matches.nil?
			return nil
		else
			matches
		end
	end

	def generateMatchups
		@matches = Tournamentmatchgen.new(self).genMatches()
	end

	def destroyAllMatches
		matches.destroy_all
	end

end
