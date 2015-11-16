class School < ActiveRecord::Base
	belongs_to :tournament
	has_many :wrestlers, dependent: :destroy
	has_many :deductedPoints, through: :wrestlers
	

	#calculate score here
	def score
		#Add score per wrestler. Calculate score in wrestler model.
		return 0
	end
	
	def calcScore
    	#calc and save score
   	end
	
	def totalDeductedPoints
		points = 0
		self.deductedPoints.each do |d|
			points = points + d.points
		end
		points
	end
	
	def poolWins
		
	end
	
	def pinDefaultDqWins
		
	end
	
	def techFallWins
		
	end
	
	def majorWins
		
   	end
    
    def firstPlace
    	
    end
    
    def secondPlace
    	
    end
    
    def thirdPlace
    	
    end
    
    def fourthPlace
    	
    end
    
    def fifthPlace
    	
    end
    
    def sixthPlace
    	
    end
    
    def seventhPlace
    	
    end
end
