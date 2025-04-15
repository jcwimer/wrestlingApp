class Mat < ApplicationRecord
	belongs_to :tournament
	has_many :matches, dependent: :destroy
	has_many :mat_assignment_rules, dependent: :destroy

	validates :name, presence: true

	before_destroy do
		if tournament.matches.size > 0
			tournament.reset_mats
			matsToAssign = tournament.mats.select{|m| m.id != self.id}
			tournament.assign_mats(matsToAssign)
		end
	end

	after_create do
		if tournament.matches.size > 0
			tournament.reset_mats
			matsToAssign = tournament.mats
			tournament.assign_mats(matsToAssign)
		end
	end

	def assign_next_match
		match = next_eligible_match
		self.matches.reload
		if match and self.unfinished_matches.size < 4
			match.mat_id = self.id
			if match.save
				# Invalidate any wrestler caches
				if match.w1
					match.wrestler1.touch
					match.wrestler1.school.touch
				end
				if match.w2
					match.wrestler2.touch
					match.wrestler2.school.touch
				end
				return true
			else
				return false
			end
		else
			return true
		end
	end

	def next_eligible_match
		# Start with all matches that are either unfinished (nil or 0), have a bout number, and are ordered by bout_number
		filtered_matches = tournament.matches
									  .where(finished: [nil, 0])  # finished is nil or 0
									  .where(mat_id: nil)         # mat_id is nil
									  .where.not(bout_number: nil) # bout_number is not nil
									  .order(:bout_number)
	  
		# Filter out BYE matches
		filtered_matches = filtered_matches
							.where("loser1_name != ? OR loser1_name IS NULL", "BYE")
							.where("loser2_name != ? OR loser2_name IS NULL", "BYE")
	  
		# Apply mat assignment rules
		mat_assignment_rules.each do |rule|
		  if rule.weight_classes.any?
			# Ensure weight_classes is treated as an array
			filtered_matches = filtered_matches.where(weight_id: Array(rule.weight_classes).map(&:to_i))
		  end
	  
		  if rule.bracket_positions.any?
			# Ensure bracket_positions is treated as an array
			filtered_matches = filtered_matches.where(bracket_position: Array(rule.bracket_positions).map(&:to_s))
		  end
	  
		  if rule.rounds.any?
			# Ensure rounds is treated as an array
			filtered_matches = filtered_matches.where(round: Array(rule.rounds).map(&:to_i))
		  end
		end
	  
		# Return the first match in filtered results, or nil if none are left
		filtered_matches.first
	end			
	  

	def unfinished_matches
		matches.select{|m| m.finished != 1}.sort_by{|m| m.bout_number}
	end

end
