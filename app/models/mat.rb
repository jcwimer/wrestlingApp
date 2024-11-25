class Mat < ApplicationRecord
	belongs_to :tournament
	has_many :matches
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
		if match
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
		filtered_matches = tournament.matches.where(finished: [nil, 0]).where(mat_id: nil).where.not(bout_number: nil).order(:bout_number)

		# Sequentially apply each rule, narrowing down the matches
		mat_assignment_rules.each do |rule|
		  if rule.weight_classes.any?
			filtered_matches = filtered_matches.where(weight_id: rule.weight_classes)
		  end
	  
		  if rule.bracket_positions.any?
			filtered_matches = filtered_matches.where(bracket_position: rule.bracket_positions)
		  end
	  
		  if rule.rounds.any?
			filtered_matches = filtered_matches.where(round: rule.rounds)
		  end
		end
	  
		# Return the first match in filtered results, or nil if none are left
		result = filtered_matches.first
		result
	end
	  

	def unfinished_matches
		matches.select{|m| m.finished != 1}.sort_by{|m| m.bout_number}
	end

end
