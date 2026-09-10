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
	before_validation :set_date_sort_key
	after_commit :invalidate_cached_views, on: :update

	attr_accessor :import_text

	private

	def invalidate_cached_views
		changes = previous_changes.except("updated_at")
		TournamentCacheInvalidator.tournament_changed(self, changes) if changes.any?
	end

	public

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
		CalculateTournamentTeamScoresJob.perform_later(id)
	end
	
	def create_pre_defined_weights(weight_classes)
		destroy_all_matches
		weight_ids = weights.ids
		wrestler_ids = Wrestler.where(weight_id: weight_ids).select(:id)
		Teampointadjust.where(wrestler_id: wrestler_ids).delete_all
		Wrestler.where(weight_id: weight_ids).delete_all
		Weight.where(id: weight_ids).delete_all
		weights.reset
		wrestlers.reset
		matches.reset
		weight_classes.each do |w|
			weights.create!(max: w)
		end
	end

	def destroy_with_dependents!
		school_ids = schools.ids
		weight_ids = weights.ids
		wrestler_ids = Wrestler.where(weight_id: weight_ids).select(:id)
		adjustments = Teampointadjust.where(school_id: school_ids)
			.or(Teampointadjust.where(wrestler_id: wrestler_ids))

		matches.delete_all
		adjustments.delete_all
		SchoolDelegate.where(school_id: school_ids).delete_all
		TournamentDelegate.where(tournament_id: id).delete_all
		MatAssignmentRule.where(tournament_id: id).delete_all
		TournamentBackup.where(tournament_id: id).delete_all
		TournamentJobStatus.where(tournament_id: id).delete_all
		Wrestler.where(weight_id: weight_ids).delete_all
		School.where(id: school_ids).delete_all
		Weight.where(id: weight_ids).delete_all
		Mat.where(tournament_id: id).delete_all

		%w[schools weights mats wrestlers matches delegates mat_assignment_rules tournament_backups tournament_job_statuses].each do |association_name|
			association(association_name.to_sym).reset
		end
		destroy!
	end

	def up_matches_unassigned_matches
		records = matches
			.where("mat_id is NULL and (finished != 1 or finished is NULL)")
			.where("loser1_name != ? OR loser1_name IS NULL", "BYE")
			.where("loser2_name != ? OR loser2_name IS NULL", "BYE")
			.order("bout_number ASC")
			.limit(10)
			.includes({ wrestler1: :school }, { wrestler2: :school }, :weight)
			.to_a
		preload_up_matches_first_rounds(records)
	end

	def up_matches_mats
		mat_records = mats.to_a
		match_ids = mat_records.flat_map(&:queue_match_ids).compact
		matches_by_id = Match.where(id: match_ids)
			.includes({ wrestler1: :school }, { wrestler2: :school }, :weight)
			.index_by(&:id)
		preload_up_matches_first_rounds(matches_by_id.values)
		mat_records.each { |mat| mat.preload_queue_matches(matches_by_id) }
		mat_records
	end

	def self.broadcast_up_matches_board(tournament_id)
		tournament = find_by(id: tournament_id)
		return unless tournament

		Turbo::StreamsChannel.broadcast_replace_to(
			tournament,
			target: "up_matches_board",
			partial: "tournaments/up_matches_board",
			locals: { tournament: tournament }
		)
	end

	def destroy_all_matches
		matches.delete_all
		reset_mats
	end

	def matches_by_round(round)
		matches.joins(:weight).where(round: round).order("weights.max")
	end
	
	def total_rounds
		# Assuming this is line 147 that's causing the error
		matches.maximum(:round) || 0  # Return 0 if no matches or max round is nil
	end
	
	def reset_mats(broadcast: true)
		mat_records = mats.to_a
		timestamp = Time.current
		matches.where.not(mat_id: nil).update_all(mat_id: nil, updated_at: timestamp)
		mat_records.each do |mat|
			mat.update_columns(queue1: nil, queue2: nil, queue3: nil, queue4: nil, updated_at: timestamp)
			Mat::QUEUE_SLOTS.each { |slot| mat.public_send("#{slot}=", nil) }
		end
		broadcast_bout_board_changes(mat_records) if broadcast
	end
	
	def pointAdjustments
	  school_scope = Teampointadjust.where(school_id: schools.select(:id))
	  wrestler_scope = Teampointadjust.where(wrestler_id: wrestlers.select(:id))

	  Teampointadjust.includes(:school, :wrestler)
	               .merge(school_scope.or(wrestler_scope))
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
        if self.tournament_type == "Regular Double Elimination 1-6" or self.tournament_type == "Regular Double Elimination 1-8"
        	weights_with_too_many_wrestlers = weights.select{|w| w.wrestlers.size > 64}
        	weight_with_too_few_wrestlers = weights.select{|w| w.wrestlers.size < 2}
        	weights_with_too_many_wrestlers.each do |weight|
        		error_string = error_string + " The weight class #{weight.max} has more than 64 wrestlers."
        	end
        	weight_with_too_few_wrestlers.each do |weight|
        		error_string = error_string + " The weight class #{weight.max} has less than 2 wrestlers."
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
		MatQueueOperation.new(self).reset_and_fill
	end

	def refill_open_bout_board_queues(broadcast_all: false, invalidate_cached_views: true)
		MatQueueOperation.new(self).refill(invalidate_cached_views:)
		mats.reset
		matches.reset
	end

	def create_backup()
		TournamentServices::TournamentBackupService.new(self, "Manual backup").create_backup
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

	def preload_up_matches_first_rounds(matches)
		weight_ids = matches.map(&:weight_id).compact.uniq
		first_rounds = Match.where(weight_id: weight_ids).group(:weight_id).minimum(:round)
		matches.each { |match| match.instance_variable_set(:@first_round_for_weight, first_rounds[match.weight_id]) }
		matches
	end

	def broadcast_bout_board_changes(mat_records)
		cache_values = Rails.cache.read_multi(*mat_records.flat_map { |mat|
			[mat.scoreboard_selection_cache_key, mat.last_match_result_cache_key]
		})
		mat_records.each do |mat|
			mat.broadcast_legacy_mat_view
			mat.broadcast_scoreboard_state(
				selection: cache_values[mat.scoreboard_selection_cache_key],
				last_match_result: cache_values[mat.last_match_result_cache_key]
			)
		end
		self.class.broadcast_up_matches_board(id)
	end

	def set_date_sort_key
		self.date_sort_key = date.jd if date
	end
	
	def connection_adapter
	  ActiveRecord::Base.connection.adapter_name
	end
end
