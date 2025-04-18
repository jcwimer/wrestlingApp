class Tournament < ApplicationRecord

	belongs_to :user, optional: true
	has_many :schools, dependent: :destroy
	has_many :weights, dependent: :destroy
	has_many :mats, dependent: :destroy
	has_many :wrestlers, through: :weights
	has_many :matches, dependent: :destroy
	has_many :delegates, class_name: "TournamentDelegate", dependent: :destroy
	has_many :mat_assignment_rules, dependent: :destroy
	has_many :tournament_backups, dependent: :destroy
	has_many :tournament_job_statuses, dependent: :destroy
	
	validates :date, :name, :tournament_type, :address, :director, :director_email , presence: true

	attr_accessor :import_text

	def self.search_date_name(pattern)
		if pattern.blank?  # blank? covers both nil and empty string
			all
		else
			search_functions = []
			search_variables = []
			search_terms = pattern.split(' ').map{|word| "%#{word.downcase}%"}
			search_terms.each do |word|
				search_functions << '(LOWER(name) LIKE ? or LOWER(date) LIKE ?)'
				# add twice for both ?'s in the function above
				search_variables << word
				search_variables << word
			end
			like_patterns = search_functions.join(' and ')
			# puts "where(#{like_patterns})"
			# puts *search_variables
			# example: (LOWER(name LIKE ? or LOWER(date) LIKE ?) and (LOWER(name) LIKE ? or LOWER(date) LIKE ?), %test%, %test%, %2016%, %2016%
			where("#{like_patterns}", *search_variables)
		end
	end

	def days_until_start
		time = (Date.today - self.date).to_i
		if time < 0
			time = time * -1
		end
		time
	end

	def tournament_types
		["Pool to bracket","Modified 16 Man Double Elimination 1-6","Modified 16 Man Double Elimination 1-8","Regular Double Elimination 1-6","Regular Double Elimination 1-8"]
	end
	
	def number_of_placers
		if self.tournament_type.include? "1-8"
			return 8
		elsif self.tournament_type.include? "1-6"
		  return 6
		end
	end
	
	def calculate_all_team_scores
		self.schools.each do |school|
      school.calculate_score
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
		# Assuming this is line 147 that's causing the error
		matches.maximum(:round) || 0  # Return 0 if no matches or max round is nil
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
  	
  	def pool_to_bracket_number_of_wrestlers_error
  		error_string = ""
      if self.tournament_type.include? "Pool to bracket"
       	weights_with_too_many_wrestlers = weights.select{|w| w.wrestlers.size > 24}
       	weight_with_too_few_wrestlers = weights.select{|w| w.wrestlers.size < 2}
       	weights_with_too_many_wrestlers.each do |weight|
       		error_string = error_string + " The weight class #{weight.max} has more than 24 wrestlers."
       	end
       	weight_with_too_few_wrestlers.each do |weight|
       		error_string = error_string + " The weight class #{weight.max} has less than 2 wrestlers."
       	end
      end
      return error_string
  	end

  	def modified_sixteen_man_number_of_wrestlers_error
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

  	def double_elim_number_of_wrestlers_error
  		error_string = ""
        if self.tournament_type == "Double Elimination 1-6" or self.tournament_type == "Double Elimination 1-8"
        	weights_with_too_many_wrestlers = weights.select{|w| w.wrestlers.size > 32}
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

	def wrestlers_with_higher_seed_than_bracket_size_error
		error_string = ""
		weights.each do |weight|
			weight.wrestlers.each do |wrestler|
				if wrestler.original_seed != nil && wrestler.original_seed > weight.wrestlers.size
					error_string += "Wrestler: #{wrestler.name} has a seed of #{wrestler.original_seed} which is greater than the amount of wrestlers (#{weight.wrestlers.size}) in the weight class #{weight.max}."
				end
			end
		end
		return error_string
	end

	def wrestlers_with_duplicate_original_seed_error
		error_string = ""
		weights.each do |weight|
			weight.wrestlers.select{|wr| wr.original_seed != nil}.each do |wrestler|
				if weight.wrestlers.select{|wr| wr.original_seed == wrestler.original_seed}.size > 1
					error_string += "More than 1 wrestler in the #{weight.max} weight class is seeded #{wrestler.original_seed}."
				end
			end
		end
		return error_string
	end
  	
	def wrestlers_with_out_of_order_seed_error
		error_string = ""
		weights.each do |weight|
		  original_seeds = weight.wrestlers.map(&:original_seed).compact.sort
		  if original_seeds.any? && original_seeds != (original_seeds.first..original_seeds.last).to_a
			error_string += "The weight class #{weight.max} has wrestlers with out-of-order seeds: #{original_seeds}. There is a gap in the sequence."
		  end
		end
		return error_string
	end
	  
	def match_generation_error
		error_string = ""
		if pool_to_bracket_number_of_wrestlers_error.length > 0
		  error_string += pool_to_bracket_number_of_wrestlers_error
		elsif modified_sixteen_man_number_of_wrestlers_error.length > 0
		  error_string += modified_sixteen_man_number_of_wrestlers_error
		elsif double_elim_number_of_wrestlers_error.length > 0
		  error_string += double_elim_number_of_wrestlers_error
		elsif wrestlers_with_higher_seed_than_bracket_size_error.length > 0
		  error_string += wrestlers_with_higher_seed_than_bracket_size_error
		elsif wrestlers_with_duplicate_original_seed_error.length > 0
		  error_string += wrestlers_with_duplicate_original_seed_error
		elsif wrestlers_with_out_of_order_seed_error.length > 0
		  error_string += wrestlers_with_out_of_order_seed_error
		end
		if error_string.length > 0
		  return "There is a tournament error. #{error_string}"
		else
		  return nil
		end
	end	  

	def reset_and_fill_bout_board
		reset_mats
	  
		if mats.any?
		  4.times do
			# Iterate over each mat and assign the next available match
			mats.each do |mat|
			  match_assigned = mat.assign_next_match
			  # If no more matches are available, exit early
			  unless match_assigned
				puts "No more eligible matches to assign."
				return
			  end
			end
		  end
		end
	end

	def create_backup()
		TournamentBackupService.new(self, "Manual backup").create_backup
	end	  

	def confirm_all_weights_have_original_seeds
	  error_string = wrestlers_with_higher_seed_than_bracket_size_error
	  error_string += wrestlers_with_duplicate_original_seed_error
	  error_string += wrestlers_with_out_of_order_seed_error
	  
	  return error_string.blank?
	end

	def confirm_each_weight_class_has_correct_number_of_wrestlers
	  error_string = pool_to_bracket_number_of_wrestlers_error
	  error_string += modified_sixteen_man_number_of_wrestlers_error
	  error_string += double_elim_number_of_wrestlers_error
	  
	  return error_string.blank?
	end
	  
	# Check if there are any active jobs for this tournament
	def has_active_jobs?
	  tournament_job_statuses.active.exists?
	end
	
	# Get all active jobs for this tournament
	def active_jobs
	  tournament_job_statuses.active
	end
	
	private
	
	def connection_adapter
	  ActiveRecord::Base.connection.adapter_name
	end
end