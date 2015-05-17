class Wrestler < ActiveRecord::Base
	belongs_to :school
	belongs_to :weight
	has_one :tournament, through: :weight
	attr_accessor :poolNumber
	
	before_save do
		self.tournament.destroyAllMatches
	end
	
	
	def isWrestlingThisRound(matchRound)
		if allMatches.blank?
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
		@match = allMatches.select{|m| m.round == round}.first
		if @match.blank?
			return "BYE"
		else
			return @match.bout_number
		end
	end
	
	def allMatches
		@matches = Match.where("w1 = ? or w2 = ?",self.id,self.id)
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
