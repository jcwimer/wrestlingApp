class Teampointadjust < ActiveRecord::Base
    belongs_to :wrestler, touch: true
    belongs_to :school, touch: true
    
    after_save do
        advance_wrestlers_and_calc_team_score
	end
	
	after_destroy do
       advance_wrestlers_and_calc_team_score 
	end
	
	def advance_wrestlers_and_calc_team_score
	    #Team score needs calculated
        if self.wrestler_id != nil
            #In case this affects pool order
            if self.wrestler.lastFinishedMatch
	            self.wrestler.lastFinishedMatch.advance_wrestlers
	        end
	        self.wrestler.school.calcScore
	    elsif self.school_id != nil
	        self.school.calcScore
	    end
	end
	if Rails.env.production?
		handle_asynchronously :advance_wrestlers_and_calc_team_score
	end
end
