class PlacementPoints
	def initialize(number_of_placers)
		@number_of_placers = number_of_placers
    end

    def firstPlace
        if @number_of_placers == 4
            return 14
        else    
            return 16
        end
    end
    
    def secondPlace
        if @number_of_placers == 4
            return 10
        else    
            return 12
        end
    end
    
    def thirdPlace
        if @number_of_placers == 4
            return 7
        else    
            return 9
        end
    end
    
    def fourthPlace
        if @number_of_placers == 4
            return 4
        else    
            return 7
        end
    end
    
    def fifthPlace
        5  
    end
    
    def sixthPlace
        3  
    end
    
    def seventhPlace
        2  
    end
    
    def eighthPlace
        1 
    end
end