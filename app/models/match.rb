class Match < ActiveRecord::Base
	belongs_to :tournament, touch: true
	belongs_to :weight, touch: true
	belongs_to :mat, touch: true
	has_many :wrestlers, :through => :weight

	

	after_update do 
	   if self.finished == 1 && self.winner_id != nil
	   	if self.w1 && self.w2
		   	wrestler1.touch
		   	wrestler2.touch
		end
		advance_wrestlers
		calcSchoolPoints
	   end
	end

	WIN_TYPES = ["Decision", "Major", "Tech Fall", "Pin", "Forfeit", "Injury Default", "Default", "DQ"]

	def calcSchoolPoints
		if self.w1 && self.w2
			wrestler1.school.calcScore
			wrestler2.school.calcScore
	   	end	
	end
	if Rails.env.production?
		handle_asynchronously :calcSchoolPoints
	end

	def mat_assigned
		if self.mat
			"Mat #{self.mat.name}"
		else
			""
		end
	end
	
	def pinTime
		if self.win_type == "Pin"
			time = self.score.delete("")
			minInSeconds = time.partition(':').first.to_i * 60
			sec = time.partition(':').last.to_i
			return minInSeconds + sec
		else
			nil
		end
	end

	def advance_wrestlers
	   if self.w1 && self.w2	
		@w1 = wrestler1
		@w2 = wrestler2
		@w1.advanceInBracket
		@w2.advanceInBracket
		if self.mat
			self.mat.assignNextMatch
		end
	   end
	end
	if Rails.env.production?
		handle_asynchronously :advance_wrestlers
	end

	def bracketScore
		if self.finished != 1
		  return ""
		end
		if self.finished == 1
		  if self.win_type == "Default"
		  	return "Def"
		  elsif self.win_type == "Injury Default"
		  	return "Inj"
		  elsif self.win_type == "DQ"
		  	return "DQ"
		  elsif self.win_type == "Forfeit"
		  	return "For"
		  else
		  	return "(#{self.score})"
		  end
		end
	end

	def wrestler1
		wrestlers.select{|w| w.id == self.w1}.first
	end

	def wrestler2
		wrestlers.select{|w| w.id == self.w2}.first
	end

	def w1_name
		if self.w1 != nil
			wrestler1.name
		else
			self.loser1_name
		end
	end

	def w2_name
		if self.w2 != nil
			wrestler2.name
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
		self.weight.max
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
			wrestler1.generatePoolNumber
		end
	end
end
