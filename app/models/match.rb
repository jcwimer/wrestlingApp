class Match < ActiveRecord::Base
	belongs_to :tournament
	WIN_TYPES = ["Decision", "Major", "Tech Fall", "Pin", "Forfeit", "Injury Default", "Default", "DQ"]
	attr_accessor :weight_max, :w1_name, :w1_name

	def weight_max
		@guy = Wrestler.find(self.r_id)
		@weight = Weight.find(@guy.weight_id)
		return @weight.max
	end

	def w1_name
		return Wrestler.find(self.r_id).name
	end

	def w2_name
		return Wrestler.find(self.g_id).name
	end


end
