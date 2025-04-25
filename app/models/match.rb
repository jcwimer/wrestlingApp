class Match < ApplicationRecord
	belongs_to :tournament, touch: true
	belongs_to :weight, touch: true
	belongs_to :mat, touch: true, optional: true
	belongs_to :winner, class_name: 'Wrestler', foreign_key: 'winner_id', optional: true
	has_many :wrestlers, :through => :weight
	has_many :schools, :through => :wrestlers
	validate :score_validation, :win_type_validation, :bracket_position_validation, :overtime_type_validation
	
	# Callback to update finished_at when a match is finished
	before_save :update_finished_at

	after_update :after_finished_actions, if: -> { 
		saved_change_to_finished? || 
		saved_change_to_winner_id? || 
		saved_change_to_win_type? || 
		saved_change_to_score? || 
		saved_change_to_overtime_type?
	}

	def after_finished_actions
	  if self.w1
		wrestler1.touch
	  end
	  if self.w2
		wrestler2.touch
	  end
	  if self.finished == 1 && self.winner_id != nil
		if self.mat
			self.mat.assign_next_match
		end
		advance_wrestlers
		calculate_school_points
	  end
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
		    	errors.add(:score, "needs to be in time format MM:SS when win type is Pin example: 1:23 or 10:03")
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
	   if self.w1
		AdvanceWrestler.new(wrestler1, self).advance
	   end
	   if self.w2
	   	AdvanceWrestler.new(wrestler2, self).advance
       end
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

	def wrestler1
		wrestlers.select{|w| w.id == self.w1}.first
	end

	def wrestler2
		wrestlers.select{|w| w.id == self.w2}.first
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
	  return_string = ""
	  return_string_ending = ""
      if self.w1 and self.winner_id == self.w1
      	return_string = return_string + "<strong>"
      	return_string_ending = return_string_ending + "</strong>"
      end
      if self.w1 != nil
      	if self.round == 1
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
		return_string = ""
		return_string_ending = ""
		if self.w2 and self.winner_id == self.w2
			return_string = return_string + "<strong>"
			return_string_ending = return_string_ending + "</strong>"
		end
		if self.w2 != nil
			if self.round == 1
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

	def update_finished_at
	  # Get the changes that will be persisted
	  changes = changes_to_save

	  # Check if finished is changing from 0 to 1 or if it's already 1 but has no timestamp
	  if (changes['finished'] && changes['finished'][1] == 1) || (finished == 1 && finished_at.nil?)
	    self.finished_at = Time.current.utc
	  end
	end
end
