class Match < ActiveRecord::Base
	belongs_to :tournament
	WIN_TYPES = ["Decision", "Major", "Tech Fall", "Pin", "Forfeit", "Injury Default", "Default", "DQ"]
	attr_accessor :weight_max

	def weight_max
		@guy = Wrestler.find(self.r_id)
		@weight = Weight.find(@guy.weight_id)
		return @weight.max
	end
end
