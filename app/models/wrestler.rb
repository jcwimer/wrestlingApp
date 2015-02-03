class Wrestler < ActiveRecord::Base
	belongs_to :school
	belongs_to :weight
	attr_accessor :matches_all, :isWrestlingThisRound, :boutByRound

	def isWrestlingThisRound(matchRound)
		@gMatches = Match.where(g_id: self.id, round: matchRound)
		@rMatches = Match.where(r_id: self.id, round: matchRound)
		@allMatches = @gMatches + @rMatches
		if @gMatches.blank? and @rMatches.blank?
			return false
		else
			return true
		end		
	end

	def boutByRound(round)
		@match = matches_all.select{|m| m.round == round}.first
		if @match.blank?
			return "BYE"
		else
			return @match.boutNumber
		end
	end

	def matches_all
		@gMatches = Match.where(g_id: self.id)
		@rMatches = Match.where(r_id: self.id)
		return @gMatches + @rMatches
	end

end
