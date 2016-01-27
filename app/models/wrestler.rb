class Wrestler < ActiveRecord::Base
	belongs_to :school, touch: true
	belongs_to :weight, touch: true
	has_one :tournament, through: :weight
	has_many :matches, through: :weight
	has_many :deductedPoints, class_name: "Teampointadjust"
	attr_accessor :poolNumber, :poolAdvancePoints, :originalId, :swapId
	
	validates :name, :weight_id, :school_id, presence: true

	before_destroy do 
		# self.tournament.destroyAllMatches
	end

	before_create do
		# self.tournament.destroyAllMatches
	end
		

	def lastFinishedMatch
		allMatches.select{|m| m.finished == 1}.sort_by{|m| m.bout_number}.last
	end

	def totalTeamPoints
		if self.extra
			return 0
		else
			teamPointsEarned - totalDeductedPoints
		end
	end
	
	def teamPointsEarned
		points = 0.0
		points = points + (poolWins.size * 2) + (championshipAdvancementWins.size * 2) + (consoAdvancementWins.size * 1) + (pinWins.size * 2) + (techWins.size * 1.5)	+ (majorWins.size * 1) + placementPoints
	end
	
	def placementPoints
		PoolBracketPlacementPoints.new(self).calcPoints
	end

	def totalDeductedPoints
		points = 0
		self.deductedPoints.each do |d|
			points = points + d.points
		end
		points
	end
	
	def nextMatch
		unfinishedMatches.first
	end
	
	def nextMatchPositionNumber
		pos = lastMatch.bracket_position_number
		return (pos/2.0)	
	end
	
	def lastMatch
		finishedMatches.sort_by{|m| m.round}.reverse.first
	end
	
	def winnerOfLastMatch?
		if lastMatch.winner_id == self.id
			return true
		else 
			return false
		end
	end
	
	def nextMatchBoutNumber
		if nextMatch
			nextMatch.bout_number
		else
			""
		end
	end
	
	def nextMatchMatName
		if nextMatch
			nextMatch.mat_assigned
		else
			""
		end
	end

	def unfinishedMatches
		allMatches.select{|m| m.finished != 1}.sort_by{|m| m.bout_number}
	end

	def resultByBout(bout)
	   @match = allMatches.select{|m| m.bout_number == bout and m.finished == 1}
	   if @match.size == 0
 		return ""
	   end
	   if @match.first.winner_id == self.id
		return "W #{@match.first.bracketScore}"
	   end
	   if @match.first.winner_id != self.id
		return "L #{@match.first.bracketScore}"
	   end
	end

	def matchAgainst(opponent)
		allMatches.select{|m| m.w1 == opponent.id or m.w2 == opponent.id}
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
	end

	def boutByRound(round)
		@match = allMatches.select{|m| m.round == round}.first
		if @match.blank?
			return "BYE"
		else
			return @match.bout_number
		end
	end

	def allMatches
		@matches = matches.select{|m| m.w1 == self.id or m.w2 == self.id}
		return @matches
	end
       
	def poolMatches
		@poolMatches = allMatches.select{|m| m.bracket_position == "Pool"}
		@poolMatches.select{|m| m.poolNumber == self.generatePoolNumber}
	end
	
	def championshipAdvancementWins
		matchesWon.select{|m| m.bracket_position == "Quarter" or m.bracket_position == "Semis"}
	end
	
	def consoAdvancementWins
		matchesWon.select{|m| m.bracket_position == "Conso Semis"}
	end
	
	def finishedMatches
		allMatches.select{|m| m.finished == 1}
	end

	def finishedBracketMatches
		finishedMatches.select{|m| m.bracket_position != "Pool"}
	end	

	def finishedPoolMatches
		finishedMatches.select{|m| m.bracket_position == "Pool"}
	end
	
	def matchesWon
		allMatches.select{|m| m.winner_id == self.id}	
	end
	
	def poolWins
		matchesWon.select{|m| m.bracket_position == "Pool"}
	end
	
	def pinWins
		matchesWon.select{|m| m.win_type == "Pin" ||  m.win_type == "Forfeit" ||  m.win_type == "Injury Default" ||  m.win_type == "Default" ||  m.win_type == "DQ"}
	end
	
	def techWins
		matchesWon.select{|m| m.win_type == "Tech Fall" }
	end
	
	def majorWins
		matchesWon.select{|m| m.win_type == "Major" }
	end
	
	def decisionWins
		matchesWon.select{|m| m.win_type == "Decision" }
	end
	
	def decisionPointsScored
		pointsScored = 0
		decisionWins.each do |m|
			scoreOfMatch = m.score.delete(" ")
			scoreOne = scoreOfMatch.partition('-').first.to_i
			scoreTwo = scoreOfMatch.partition('-').last.to_i
			if scoreOne > scoreTwo
				pointsScored = pointsScored + scoreOne
			elsif scoreTwo > scoreOne
				pointsScored = pointsScored + scoreTwo
			end
		end
		pointsScored
	end
	
	def fastestPin
		pinWins.sort_by{|m| m.pinTime}.first
	end
	
	def seasonWinPercentage
		win = self.season_win.to_f
		loss = self.season_loss.to_f
		if win > 0 and loss != nil
			matchTotal = win + loss
			percentageDec = win / matchTotal
			percentage = percentageDec * 100
			return percentage.to_i
		elsif self.season_win == 0
			return 0
		elsif self.season_win == nil or self.season_loss == nil
			return 0
		end
	end

	def advanceInBracket(match)
		PoolAdvance.new(self,match).advanceWrestler
	end
end
