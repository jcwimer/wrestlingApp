class Wrestler < ActiveRecord::Base
	belongs_to :school
	belongs_to :weight
	attr_accessor :allMatches, :isWrestlingThisRound, :boutByRound, :seasonWinPercentage

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

	def generatePoolNumber
		@pool = self.weight.returnPoolNumber(self)
		return @pool
	end

	def boutByRound(round,matches)
		@matches = matches.select{|m| m.w1 == self.id || m.w2 == self.id}
		@match = @matches.select{|m| m.round == round}.first
		if @match.blank?
			return "BYE"
		else
			return @match.boutNumber
		end
	end
	
	def allMatches(matches)
		@matches = matches.select{|m| m.w1 == self.id || m.w2 == self.id}
		return @matches
	end


	def seasonWinPercentage
		@win = self.season_win.to_f
		@loss = self.season_loss.to_f
		if @win > 0 and @loss != nil
			@matchTotal = @win + @loss
			@percentageDec = @win / @matchTotal
			@percentage = @percentageDec * 100
			return @percentage.to_i
		elsif self.season_win == 0
			return 0
		elsif self.season_win == nil or self.season_loss == nil
			return 0	
		end
	end

end
