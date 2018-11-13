class Tournament < ActiveRecord::Base

	belongs_to :user
	has_many :schools, dependent: :destroy
	has_many :weights, dependent: :destroy
	has_many :mats, dependent: :destroy
	has_many :wrestlers, through: :weights
	has_many :matches, dependent: :destroy
	has_many :delegates, class_name: "TournamentDelegate"
	
	validates :date, :name, :tournament_type, :address, :director, :director_email , presence: true

	def self.search(search)
	  where("date LIKE ? or name LIKE ?", "%#{search}%", "%#{search}%")
	end

	def days_until_start
		time = (Date.today - self.date).to_i
		if time < 0
			time = time * -1
		end
		time
	end

	def tournament_types
		["Pool to bracket"]
	end

	def create_pre_defined_weights(value)
		weights.destroy_all
		if value == 'hs'
			Weight::HS_WEIGHT_CLASSES.each do |w|
				weights.create(max: w)
			end
		else
			raise "Unspecified behavior"
		end
	end

	def destroy_all_matches
		matches.destroy_all
	end

	def matches_by_round(round)
		matches.joins(:weight).where(round: round).order("weights.max")
	end
	
	def total_rounds
		self.matches.sort_by{|m| m.round}.last.round	
	end
	
	def assign_mats(mats_to_assign)
		if mats_to_assign.count > 0
			until mats_to_assign.sort_by{|m| m.id}.last.matches.count == 4
				mats_to_assign.sort_by{|m| m.id}.each do |m|
					m.assign_next_match	
				end
			end	
		end
	end
	
	def reset_mats
		matches_to_reset = matches.select{|m| m.mat_id != nil}
		# matches_to_reset.update_all( {:mat_id => nil } )
		matches_to_reset.each do |m|
			m.mat_id = nil
			m.save
		end
	end
	
	def pointAdjustments
	  point_adjustments = []
      self.schools.each do |s|
        s.deductedPoints.each do |d|
          point_adjustments << d
        end
      end
      self.wrestlers.each do |w|
        w.deductedPoints.each do |d|
          point_adjustments << d
        end
      end
      point_adjustments
    end
    
    def remove_school_delegations
	    self.schools.each do |s|
	      s.delegates.each do |d|
	        d.destroy
	      end
	    end
  	end
  	
  	def pool_to_bracket_weights_with_too_many_wrestlers
  		if self.tournament_type == "Pool to bracket"
  			weightsWithTooManyWrestlers = weights.select{|w| w.wrestlers.size > 16}
  			if weightsWithTooManyWrestlers.size < 1
  				return nil
  			else
  				return weightsWithTooManyWrestlers
  			end
  		else
  			nil
  		end
  	end
  	
  	def match_generation_error
  		errorString = "There is a tournament error."
  		if pool_to_bracket_weights_with_too_many_wrestlers != nil
  			errorString = errorString + " The following weights have too many wrestlers "
  			pool_to_bracket_weights_with_too_many_wrestlers.each do |w|
  				errorString = errorString + "#{w.max} "
  			end
  			return errorString
  		else
  			nil
  		end
  	end
  	
  	
  	
end
