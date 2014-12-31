class Match < ActiveRecord::Base
	belongs_to :tournament
	WIN_TYPES = ["Decision", "Major", "Tech Fall", "Pin", "Forfeit", "Injury Default", "Default"]

	
end
