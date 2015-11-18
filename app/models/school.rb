class School < ActiveRecord::Base
	belongs_to :tournament
	has_many :wrestlers, dependent: :destroy
	has_many :deductedPoints, through: :wrestlers
	

	#calculate score here
	def pageScore
		if self.score == nil
			return 0.0
		else
			return self.score
		end
	end
	
	def calcScore
    	newScore = totalWrestlerPoints - totalDeductedPoints
    	self.score = newScore
    	self.save
   	end
	
	def totalWrestlerPoints
		points = 0
		self.wrestlers.each do |w|
			points = points + w.totalTeamPoints
		end
		points
	end
	
	def totalDeductedPoints
		points = 0
		self.deductedPoints.each do |d|
			points = points + d.points
		end
		points
	end
end
