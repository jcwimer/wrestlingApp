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



