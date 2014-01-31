class Match < ActiveRecord::Base
	belongs_to :tournament
	WIN_TYPES = ["Decision", "Major", "Tech Fall", "Pin", "Forfeit", "Injury Default", "Default"]

	def bout
		@round_number = self.round * 1000

		self.bout_number = @round_number + self.id
	end
end
