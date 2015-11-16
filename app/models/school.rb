class School < ActiveRecord::Base
	belongs_to :tournament
	has_many :wrestlers, dependent: :destroy
	has_many :deductedPoints, through: :wrestlers
	

	#calculate score here
	def score
		calcScore
	end
	
	def calcScore
    	totalWrestlerPoints - totalDeductedPoints
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
