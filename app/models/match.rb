class Match < ApplicationRecord
	include ActionView::RecordIdentifier

	RESULT_FIELDS = %w[finished winner_id win_type score overtime_type].freeze
	STAT_FIELDS = %w[w1_stat w2_stat].freeze
	STRUCTURAL_FIELDS = %w[w1 w2 weight_id tournament_id bout_number bracket_position bracket_position_number round loser1_name loser2_name].freeze

	belongs_to :tournament
	belongs_to :weight
	belongs_to :mat, optional: true
	belongs_to :winner, class_name: 'Wrestler', foreign_key: 'winner_id', optional: true
	belongs_to :wrestler1, class_name: 'Wrestler', foreign_key: 'w1', optional: true
	belongs_to :wrestler2, class_name: 'Wrestler', foreign_key: 'w2', optional: true
	has_many :wrestlers, :through => :weight
	has_many :schools, :through => :wrestlers
	validate :score_validation, :win_type_validation, :bracket_position_validation, :overtime_type_validation, :winner_validation
	
	# Callback to update finished_at when a match is finished
	before_save :update_finished_at
	after_save :remember_result_change

	# update mat show with correct match if bout board is reset
	# this is done with a turbo stream
	after_commit :broadcast_mat_assignment_change, if: :saved_change_to_mat_id?, on: [:create, :update]
	after_commit :broadcast_up_matches_board, on: :update, if: :saved_change_to_mat_id?
	after_commit :invalidate_created_or_destroyed_match, on: [:create, :destroy]
	after_commit :invalidate_structural_caches, on: :update, if: :structural_fields_changed?
	after_commit :handle_result_change, on: :update, if: :result_fields_changed?
	after_commit :invalidate_finished_stat_caches, on: :update, if: :finished_stats_changed?

	def finalize_once!
		with_lock do
			reload
			return false unless finished == 1 && winner_id.present? && finalized_at.nil?

			assigned_mat = mat
			update_column(:finalized_at, Time.current)
			promote_queue1_if_current_match!(assigned_mat)
			enqueue_post_finalize_jobs!
		end
		true
	end

	def result_changed_in_last_save?
		@result_fields_changed_on_save
	end
    
    BRACKET_POSITIONS = ["Pool","1/2","3/4","5/6","7/8","Quarter","Semis","Conso Semis","Bracket","Conso", "Conso Quarter"]
	WIN_TYPES = ["Decision", "Major", "Tech Fall", "Pin", "Forfeit", "Injury Default", "Default", "DQ", "BYE"]
	OVERTIME_TYPES = ["", "SV-1", "TB-1", "UTB", "SV-2", "TB-2", "OT"] # had to keep the blank here for validations
	
	def score_validation
		if finished == 1
			if ! winner_id
				errors.add(:winner_id, "cannot be blank")
			end
		    if win_type == "Pin" and ! score.match(/^[0-5]?[0-9]:[0-5][0-9]/)
		    	errors.add(:score, "needs to be in time format MM:SS when win type is Pin example: 2:23, 0:25, 10:03")
		    end
		    if win_type == "Decision" or win_type == "Tech Fall" or win_type == "Major" and ! score.match(/^[0-9]?[0-9]-[0-9]?[0-9]/)
		    	errors.add(:score, "needs to be in Number-Number format when win type is Decision, Tech Fall, and Major example: 10-2")
		    end
		    if (win_type == "Forfeit" or win_type == "Injury Default" or win_type == "Default" or win_type == "BYE" or win_type == "DQ") and (score != "")
		    	errors.add(:score, "needs to be blank when win type is Forfeit, Injury Default, Default, BYE, or DQ win_type")
		    end
		end
	end
	
	def win_type_validation
	  if finished == 1
	    if ! WIN_TYPES.include? win_type
	  	  errors.add(:win_type, "can only be one of the following #{WIN_TYPES.to_s}")
	    end
	  end
	end

	def winner_validation
		return unless winner_id
		return if [w1, w2].compact.include?(winner_id)

		errors.add(:winner_id, "must be one of the wrestlers in the match")
	end
	
	def overtime_type_validation
	  # overtime_type can be nil or of type OVERTIME_TYPES
	  if overtime_type != nil and ! OVERTIME_TYPES.include? overtime_type
	  	  errors.add(:overtime_type, "can only be one of the following #{OVERTIME_TYPES.to_s}")
	  end
	end
	
	def bracket_position_validation
		# Allow "Bracket Round of 16", "Bracket Round of 16.1", 
		# "Conso Round of 8", "Conso Round of 8.2", etc.
		bracket_round_regex = /\A(Bracket|Conso) Round of \d+(\.\d+)?\z/
	
		unless BRACKET_POSITIONS.include?(bracket_position) || bracket_position.match?(bracket_round_regex)
		  errors.add(:bracket_position, 
			"must be one of #{BRACKET_POSITIONS.to_s} " \
			"or match the pattern 'Bracket Round of X'/'Conso Round of X'")
		end
	end

	def is_consolation_match
        if self.bracket_position.include? "Conso" or self.bracket_position == "3/4" or self.bracket_position == "5/6" or self.bracket_position == "7/8"
        	return true
        else
        	return false
        end
	end

	def is_championship_match
        if self.bracket_position == "Pool" or self.bracket_position == "Quarter" or self.bracket_position == "Semis" or self.bracket_position.include? "Bracket" or self.bracket_position == "1/2"
        	return true
        else
        	return false
        end
	end

	def calculate_school_points
		if self.w1 && self.w2
			wrestler1.school.calculate_score
			wrestler2.school.calculate_score
	   	end
	end

    def wrestler_in_match(wrestler)
        if self.w1 == wrestler.id or self.w2 == wrestler.id
            return true
        else
        	return false
        end
    end

	def mat_assigned
		if self.mat
			"Mat #{self.mat.name}"
		else
			""
		end
	end

	def pin_time_in_seconds
		if self.win_type == "Pin"
			time = self.score.delete("")
			minutes_in_seconds = time.partition(':').first.to_i * 60
			sec = time.partition(':').last.to_i
			return minutes_in_seconds + sec
		else
			0
		end
	end

	def advance_wrestlers
		enqueue_post_finalize_jobs!
	end

	def enqueue_post_finalize_jobs!
		return false unless w1 || w2

		AdvanceWrestlerJob.perform_later([id], tournament_id)
		FillBoutBoardJob.perform_later(tournament_id)
		true
	end


	def bracket_score_string
		if self.finished != 1
		  return ""
		end
		if self.finished == 1
		  overtime_type_abbreviation = ""
		  if self.overtime_type != "" and self.overtime_type
		  	overtime_type_abbreviation = " #{self.overtime_type}"
		  end
		  if self.win_type == "Injury Default"
		  	return "(Inj)"
		  elsif self.win_type == "DQ"
		  	return "(DQ)"
		  elsif self.win_type == "Forfeit"
		  	return "(FF)"
		  else
		  	win_type_abbreviation = "#{self.win_type.chars.to_a[0..2].join('')}"
		  	return "(#{win_type_abbreviation} #{self.score}#{overtime_type_abbreviation})"
		  end
		end
	end

	def w1_name
		if self.w1 != nil
			wrestler1.name
		else
			self.loser1_name
		end
	end

	def w2_name
		if self.w2 != nil
			wrestler2.name
		else
			self.loser2_name
		end
	end

	def w1_bracket_name
	  first_round = first_round_for_weight
	  return_string = ""
	  return_string_ending = ""
      if self.w1 and self.winner_id == self.w1
      	return_string = return_string + "<strong>"
      	return_string_ending = return_string_ending + "</strong>"
      end
      if self.w1 != nil
      	if self.round == first_round
          return_string = return_string + "#{wrestler1.long_bracket_name}"
      	else
      	  return_string = return_string + "#{wrestler1.short_bracket_name}"
      	end
      else
      	return_string = return_string + "#{self.loser1_name}"
      end
      return return_string + return_string_ending
	end

	def w2_bracket_name
		first_round = first_round_for_weight
		return_string = ""
		return_string_ending = ""
		if self.w2 and self.winner_id == self.w2
			return_string = return_string + "<strong>"
			return_string_ending = return_string_ending + "</strong>"
		end
		if self.w2 != nil
			if self.round == first_round
			return_string = return_string + "#{wrestler2.long_bracket_name}"
			else
			  return_string = return_string + "#{wrestler2.short_bracket_name}"
			end
		else
			return_string = return_string + "#{self.loser2_name}"
		end
		return return_string + return_string_ending
	end

	def winner_name
		if self.finished != 1
			return ""
		end
		if self.winner == self.wrestler1
			return self.w1_name
		end
		if self.winner == self.wrestler2
			return self.w2_name
		end
	end

	def all_results_text
		if self.finished != 1
			return ""
		end
		winning_wrestler = self.winner
		if winning_wrestler == self.wrestler1
			losing_wrestler = self.wrestler2
		elsif winning_wrestler == self.wrestler2
			losing_wrestler = self.wrestler1
		else
			# Handle cases where winner is not w1 or w2 (e.g., BYE, DQ where opponent might be nil)
      # Or maybe the match hasn't been fully populated yet after a win?
      # Returning an empty string for now, but this might need review based on expected scenarios.
			return "" 
		end
		# Ensure losing_wrestler is not nil before accessing its properties
		losing_wrestler_name = losing_wrestler ? losing_wrestler.name : "Unknown"
		losing_wrestler_school = losing_wrestler ? losing_wrestler.school.name : "Unknown"

		return "#{self.weight.max} lbs - #{winning_wrestler.name} (#{winning_wrestler.school.name}) #{self.win_type} #{losing_wrestler_name} (#{losing_wrestler_school}) #{self.score}"
	end

    def bracket_winner_name
      # Use the winner association directly
      if self.winner
      	return "#{self.winner.name} (#{self.winner.school.abbreviation})"
      else
      	""
      end
    end

	def weight_max
		self.weight.max
	end

	def first_round_for_weight
		return @first_round_for_weight if defined?(@first_round_for_weight)

		@first_round_for_weight =
			if association(:weight).loaded? && self.weight&.association(:matches)&.loaded?
				self.weight.matches.map(&:round).compact.min
			else
				Match.where(weight_id: self.weight_id).minimum(:round)
			end
	end

	def replace_loser_name_with_wrestler(w,loser_name)
		if self.loser1_name == loser_name
			self.w1 = w.id
			self.save
		end
		if self.loser2_name == loser_name
			self.w2 = w.id
			self.save
		end
	end

    def replace_loser_name_with_bye(loser_name)
		if self.loser1_name == loser_name
			self.loser1_name = "BYE"
			self.save
		end
		if self.loser2_name == loser_name
			self.loser2_name = "BYE"
			self.save
		end
	end

	def pool_number
		if self.w1?
			wrestler1.pool
		end
	end

        def list_w2_stats
          if self.w2
            "#{w2_name} (#{wrestler2.school.name}): #{w2_stat}"
          else
          	""
          end
        end

        def list_w1_stats
          if self.w1
            "#{w1_name} (#{wrestler1.school.name}): #{w1_stat}"
          else
          	""
          end
        end
	
	private

	def promote_queue1_if_current_match!(assigned_mat)
		return unless assigned_mat&.queue1 == id

		MatQueueOperation.new(tournament).promote_after_queue1_finish!(assigned_mat, self)
	end

	def update_finished_at
	  # Get the changes that will be persisted
	  changes = changes_to_save

	  # Check if finished is changing from 0 to 1 or if it's already 1 but has no timestamp
	  if (changes['finished'] && changes['finished'][1] == 1) || (finished == 1 && finished_at.nil?)
	    self.finished_at = Time.current.utc
	  end
	end

	def handle_result_change
		winner_changed = previous_changes.key?("winner_id")
		finalized_now = finalize_once! if finished == 1 && winner_id.present?
		advancement_queued = finalized_now
		if finished == 1 && finalized_at.present? && !finalized_now
			advancement_queued = reconcile_finished_result!(winner_changed: winner_changed)
		end
		invalidate_result_caches unless advancement_queued
		broadcast_result_state
	end

	def reconcile_finished_result!(winner_changed:)
		if winner_changed
			ReconcileFinishedMatchResult.new(self).call
		else
			calculate_school_points
			false
		end
	end

	def remember_result_change
		@result_fields_changed_on_save = (saved_changes.keys & RESULT_FIELDS).any?
	end

	def result_fields_changed?
		(previous_changes.keys & RESULT_FIELDS).any?
	end

	def structural_fields_changed?
		(previous_changes.keys & STRUCTURAL_FIELDS).any?
	end

	def finished_stats_changed?
		finished == 1 && !result_fields_changed? && (previous_changes.keys & STAT_FIELDS).any?
	end

	def invalidate_finished_stat_caches
		TournamentCacheInvalidator.finished_match_stats_changed([w1, w2])
	end

	def invalidate_created_or_destroyed_match
		invalidate_result_caches
	end

	def invalidate_structural_caches
		wrestler_ids = [w1, w2]
		wrestler_ids.concat(previous_changes["w1"] || [])
		wrestler_ids.concat(previous_changes["w2"] || [])
		weight_ids = [weight_id] + (previous_changes["weight_id"] || [])
		tournament_ids = [tournament_id] + (previous_changes["tournament_id"] || [])
		invalidate_cache_records(wrestler_ids, weight_ids: weight_ids, tournament_ids: tournament_ids)
	end

	def invalidate_result_caches
		invalidate_cache_records([w1, w2])
	end

	def invalidate_cache_records(wrestler_ids, weight_ids: [weight_id], tournament_ids: [tournament_id])
		TournamentCacheInvalidator.match_changed(
			wrestler_ids: wrestler_ids,
			weight_ids: weight_ids,
			tournament_ids: tournament_ids
		)
	end

	def broadcast_result_state
		MatchChannel.broadcast_to(self, {
			w1_stat: w1_stat,
			w2_stat: w2_stat,
			score: score,
			win_type: win_type,
			winner_id: winner_id,
			winner_name: winner&.name,
			finished: finished,
			scoreboard_state: Rails.cache.read("tournament:#{tournament_id}:match:#{id}:scoreboard_state")
		})
	end

	def broadcast_mat_assignment_change
		old_mat_id, new_mat_id = saved_change_to_mat_id || previous_changes["mat_id"]
		return unless old_mat_id || new_mat_id

		[old_mat_id, new_mat_id].compact.uniq.each do |mat_id|
			mat = Mat.find_by(id: mat_id)
			next unless mat

			mat.broadcast_legacy_mat_view
			mat.broadcast_scoreboard_state
		end
		TournamentCacheInvalidator.wrestler_listings([w1, w2])
	end

	def broadcast_up_matches_board
		Tournament.broadcast_up_matches_board(tournament_id)
	end
end
