class Match < ActiveRecord::Base
	belongs_to :tournament
	belongs_to :weight
	belongs_to :mat

	after_save do 
	   if self.finished == 1
		advance_wrestlers
	   end
	end

	WIN_TYPES = ["Decision", "Major", "Tech Fall", "Pin", "Forfeit", "Injury Default", "Default", "DQ"]

	def advance_wrestlers
	   if self.w1? && self.w2?	
		@w1 = Wrestler.find(self.w1)
		@w2 = Wrestler.find(self.w2)
		@w1.advanceInBracket
		@w2.advanceInBracket
	   end
	end

	def bracketScore
		if self.finished != 1
		  return ""
		end
		if self.finished == 1
		  return "(#{self.score})"
		end
	end

	def w1_name
		if self.w1
			Wrestler.find(self.w1).name
		else
			self.loser1_name
		end
	end

	def w2_name
		if self.w2
			Wrestler.find(self.w2).name
		else
			self.loser2_name
		end
	end
	def winnerName
		if self.finished != 1
			return ""
		end
		if self.winner_id == self.w1
			return self.w1_name
		end
		if self.winner_id == self.w2
			return self.w2_name
		end
	end
	def weight_max
		Weight.find(self.weight_id).max
	end
	
	def replaceLoserNameWithWrestler(w,loserName)
		if self.loser1_name == loserName
			self.w1 = w.id
			self.save
		end
		if self.loser2_name == loserName
			self.w2 = w.id
			self.save
		end
	end
	def poolNumber
		if self.w1?
			Wrestler.find(self.w1).generatePoolNumber
		end
	end
end
