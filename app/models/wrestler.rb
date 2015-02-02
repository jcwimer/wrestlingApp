class Wrestler < ActiveRecord::Base
	belongs_to :school
	belongs_to :weight
	attr_accessor :matches_all, :isWrestlingThisRound

	def isWrestlingThisRound(round)
		@gMatches = Match.where(g_id: self.id, round: round)
		@rMatches = Match.where(r_id: self.id, round: round)
		@allMatches = @gMatches + @rMatches
		if @allMatches == nil
			return true
		else
			return false
		end		
	end

	def matches_all
		@gMatches = Match.where(g_id: self.id)
		@rMatches = Match.where(r_id: self.id)
		return @gMatches + @rMatches
	end

end
