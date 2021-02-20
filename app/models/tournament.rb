class Tournament < ActiveRecord::Base

	belongs_to :user
	has_many :schools, dependent: :destroy
	has_many :weights, dependent: :destroy
	has_many :mats, dependent: :destroy
	has_many :wrestlers, through: :weights
	has_many :matches, dependent: :destroy
	has_many :delegates, class_name: "TournamentDelegate"
	
	validates :date, :name, :tournament_type, :address, :director, :director_email , presence: true

	attr_accessor :import_text

	def deferred_jobs
        Delayed::Job.where(job_owner_id: self.id)
	end

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
		["Pool to bracket","Modified 16 Man Double Elimination 1-6","Modified 16 Man Double Elimination 1-8","Regular Double Elimination 1-6"]
	end
	
	def number_of_placers
		if self.tournament_type.include? "1-8"
			return 8
		elsif self.tournament_type.include? "1-6"
		  return 6
		end
	end
	
	def create_pre_defined_weights(weight_classes)
		weights.destroy_all
		weight_classes.each do |w|
			weights.create(max: w)
		end
	end

	def destroy_all_matches
		matches.destroy_all
	end

	def matches_by_round(round)
		matches.joins(:weight).where(round: round).order("weights.max")
	end
	
	def total_rounds
		if self.matches.count > 0
		  self.matches.sort_by{|m| m.round}.last.round
		else
		  0
		end
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
  			weightsWithTooManyWrestlers = weights.select{|w| w.wrestlers.size > 24}
  			if weightsWithTooManyWrestlers.size < 1
  				return nil
  			else
  				return weightsWithTooManyWrestlers
  			end
  		else
  			nil
  		end
  	end

  	def modified_sixteen_man_number_of_wrestlers
  		error_string = ""
        if self.tournament_type.include? "Modified 16 Man Double Elimination"
        	weights_with_too_many_wrestlers = weights.select{|w| w.wrestlers.size > 16}
        	weight_with_too_few_wrestlers = weights.select{|w| w.wrestlers.size < 12}
        	weights_with_too_many_wrestlers.each do |weight|
        		error_string = error_string + " The weight class #{weight.max} has more than 16 wrestlers."
        	end
        	weight_with_too_few_wrestlers.each do |weight|
        		error_string = error_string + " The weight class #{weight.max} has less than 12 wrestlers."
        	end
        end
        return error_string
  	end

  	def double_elim_number_of_wrestlers
  		error_string = ""
        if self.tournament_type == "Double Elimination 1-6"
        	weights_with_too_many_wrestlers = weights.select{|w| w.wrestlers.size > 16}
        	weight_with_too_few_wrestlers = weights.select{|w| w.wrestlers.size < 4}
        	weights_with_too_many_wrestlers.each do |weight|
        		error_string = error_string + " The weight class #{weight.max} has more than 16 wrestlers."
        	end
        	weight_with_too_few_wrestlers.each do |weight|
        		error_string = error_string + " The weight class #{weight.max} has less than 4 wrestlers."
        	end
        end
        return error_string
    end
  	
  	def match_generation_error
  		error_string = "There is a tournament error."
  		modified_sixteen_man_error = modified_sixteen_man_number_of_wrestlers
        double_elim_error = double_elim_number_of_wrestlers
  		if pool_to_bracket_weights_with_too_many_wrestlers != nil
  			error_string = error_string + " The following weights have too many wrestlers "
  			pool_to_bracket_weights_with_too_many_wrestlers.each do |w|
  				error_string = error_string + "#{w.max} "
  			end
  			return error_string
  		elsif modified_sixteen_man_error.length > 0
  			return error_string + modified_sixteen_man_error
  		elsif double_elim_error.length > 0
  			return error_string + double_elim_error
  		else
  			nil
  		end
  	end
end