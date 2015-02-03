class Wrestler < ActiveRecord::Base
	belongs_to :school
	belongs_to :weight
	attr_accessor :matches_all, :isWrestlingThisRound

	def isWrestlingThisRound(matchRound)
		@gMatches = Match.where(g_id: self.id, round: matchRound)
		@rMatches = Match.where(r_id: self.id, round: matchRound)
		@allMatches = @gMatches + @rMatches
		if @gMatches.blank? and @rMatches.blank?
			return false
		else
			puts "He does wrestle this round"
			return true
		end		
	end

	def matches_all
		@gMatches = Match.where(g_id: self.id)
		@rMatches = Match.where(r_id: self.id)
		return @gMatches + @rMatches
	end

end
