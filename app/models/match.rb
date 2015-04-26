class Match < ActiveRecord::Base
	belongs_to :tournament
	WIN_TYPES = ["Decision", "Major", "Tech Fall", "Pin", "Forfeit", "Injury Default", "Default", "DQ"]


	def w1_name
		if self.w1
			Wrestler.find(self.w1).name
		else
			self.loser1_name
		end
	end

	def w2_name
		if self.w2
			Wrestler.find(self.w2).name
		else
			self.loser2_name
		end
	end

	def weight_max
		Weight.find(self.weight_id).max
	end

end
