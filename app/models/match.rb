class Match < ActiveRecord::Base
	belongs_to :tournament
	WIN_TYPES = ["Decision", "Major", "Tech Fall", "Pin", "Forfeit", "Injury Default", "Default", "DQ"]


	def w1_name
		Wrestler.find(self.w1).name
	end

	def w2_name
		Wrestler.find(self.w2).name
	end

end
