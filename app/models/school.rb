class School < ActiveRecord::Base
	belongs_to :tournament
	has_many :wrestlers, dependent: :destroy
	attr_accessor :score

	#calculate score here
	def score
		@matches = self.tournament.upcomingMatches
		return 0
	end
end
