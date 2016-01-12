class School < ActiveRecord::Base
	belongs_to :tournament, touch: true
	has_many :wrestlers, dependent: :destroy
	has_many :deductedPoints, class_name: "Teampointadjust"
	has_many :delegates, class_name: "SchoolDelegate"
	
	validates :name, presence: true

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
			if w.extra != true
				points = points + w.totalTeamPoints
			end
		end
		points
	end
	
	def totalDeductedPoints
		points = 0
		deductedPoints.each do |d|
			points = points + d.points
		end
		self.wrestlers.each do |w|
			w.deductedPoints.each do |d|
				points = points + d.points
			end
		end
		points
	end
end
