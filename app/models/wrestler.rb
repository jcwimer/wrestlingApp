class Wrestler < ActiveRecord::Base
	belongs_to :school
	belongs_to :weight
	has_many :matches

	def isWrestlingThisRound?(round)
		@r_id = Match.where(r_id: self.id, round: round)
		@g_id = Match.where(g_id: self.id, round: round)
		if @r_id or @g_id
			return true
		else
			return false
		end
	end
end
