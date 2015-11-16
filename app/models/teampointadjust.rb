class Teampointadjust < ActiveRecord::Base
    belongs_to :wrestler
    
    after_save do 
	   self.wrestler.lastFinishedMatch.advance_wrestlers
	end
end
