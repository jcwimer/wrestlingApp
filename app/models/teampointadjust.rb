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
            AdvanceWrestler.new(self.wrestler).advance
	        self.wrestler.school.calculate_score
	    elsif self.school_id != nil
	        self.school.calculate_score
	    end
	end

end
