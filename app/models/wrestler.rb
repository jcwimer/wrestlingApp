class Wrestler < ActiveRecord::Base
	belongs_to :school
	belongs_to :weight
	has_many :matches

	def isWrestlingThisRound?(round)
		@r = Match.where(r_id: self.id, round: round)
		@g = Match.where(g_id: self.id, round: round)
		if @r or @g
			return true
		else
			return false
		end
	end

end
