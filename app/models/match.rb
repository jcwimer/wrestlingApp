class Match < ActiveRecord::Base
	belongs_to :tournament, touch: true
	belongs_to :weight, touch: true
	belongs_to :mat, touch: true
	has_many :wrestlers, :through => :weight
        after_update :after_finished_actions, :if => :saved_change_to_finished? or :saved_change_to_winner_id? or :saved_change_to_win_type? or :saved_change_to_score?

	def after_finished_actions
	  if self.finished == 1 && self.winner_id != nil
	  	if self.w1
		   	wrestler1.touch
		end
		if self.w2
		   	wrestler2.touch
		end
		if self.mat
			self.mat.assign_next_match
		end
		advance_wrestlers
		calculate_school_points
	  end
	end
    
    BRACKET_POSITIONS = ["Pool","1/2","3/4","5/6","7/8","Quarter","Semis","Conso Semis","Bracket","Conso", "Conso Quarter"]
	WIN_TYPES = ["Decision", "Major", "Tech Fall", "Pin", "Forfeit", "Injury Default", "Default", "DQ", "BYE"]

	def is_consolation_match
        if self.bracket_position == "Conso" or self.bracket_position == "Conso Quarter" or self.bracket_position == "Conso Semis" or self.bracket_position == "3/4" or self.bracket_position == "5/6" or self.bracket_position == "7/8"
        	return true
        else
        	return false
        end
	end

	def is_championship_match
        if self.bracket_position == "Pool" or self.bracket_position == "Quarter" or self.bracket_position == "Semis" or self.bracket_position == "Bracket" or self.bracket_position == "1/2"
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
			nil
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
		  if self.win_type == "Default"
		  	return "(Def)"
		  elsif self.win_type == "Injury Default"
		  	return "(Inj)"
		  elsif self.win_type == "DQ"
		  	return "(DQ)"
		  elsif self.win_type == "Forfeit"
		  	return "(FF)"
		  else
		  	win_type_abbreviation = "#{self.win_type.chars.to_a[0..2].join('')}"
		  	return "(#{win_type_abbreviation} #{self.score})"
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
          if self.wrestler1.original_seed
          	return_string = return_string + "[#{wrestler1.original_seed}] "
          end
          return_string = return_string + "#{w1_name} - #{wrestler1.school.name} (#{wrestler1.season_win}-#{wrestler1.season_loss})"
      	else
      	  return_string = return_string + "#{w1_name} (#{wrestler1.school.abbreviation})"
      	end
      else
      	return_string = return_string + "#{w1_name}"
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
      	  if self.wrestler2.original_seed
          	return_string = return_string + "#{wrestler2.original_seed} "
          end
          return_string = return_string + "#{w2_name} - #{wrestler2.school.name} (#{wrestler2.season_win}-#{wrestler2.season_loss})"
      	else
      	  return_string = return_string + "#{w2_name} (#{wrestler2.school.abbreviation})"
      	end
      else
      	return_string = return_string + "#{w2_name}"
      end
      return return_string + return_string_ending
	end

	def winner_name
		if self.finished != 1
			return ""
		end
		if self.winner_id == self.w1
			return self.w1_name
		end
		if self.winner_id == self.w2
			return self.w2_name
		end
	end

    def bracket_winner_name
      if winner_name != ""
      	return "#{winner_name} (#{Wrestler.find(winner_id).school.abbreviation})"
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
end
