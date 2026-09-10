class Teampointadjust < ApplicationRecord
    belongs_to :wrestler, optional: true
    belongs_to :school, optional: true
    
    after_commit on: [:create, :update] do
        advance_wrestlers_and_calc_team_score
	end
	
	after_commit on: :destroy do
       advance_wrestlers_and_calc_team_score 
	end
	
	def advance_wrestlers_and_calc_team_score
	    #Team score needs calculated
        if self.wrestler_id != nil
            wrestler = Wrestler.find_by(id: wrestler_id)
            return unless wrestler

            #In case this affects pool order
            if wrestler.last_match
                BracketAdvancement::AdvanceWrestler.new(wrestler, wrestler.last_match).advance
            else
                TournamentCacheInvalidator.wrestler_profiles([wrestler_id])
                TournamentCacheInvalidator.wrestler_listings([wrestler_id])
                wrestler.school.calculate_score
            end
        elsif self.school_id != nil
	        School.find_by(id: school_id)&.calculate_score
	    end
	end

end
