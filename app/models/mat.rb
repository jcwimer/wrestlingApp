class Mat < ActiveRecord::Base
	belongs_to :tournament
	has_many :matches

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
		t_matches = tournament.matches.select{|m| m.mat_id == nil && m.finished != 1 && m.bout_number != nil}.sort_by{|m| m.bout_number}
		if t_matches.size > 0 and self.unfinished_matches.size < 4
			match = t_matches.sort_by{|m| m.bout_number}.first
			match.mat_id = self.id
			if match.save
				return true
			else
				return false
			end
		else
			return true
		end
	end

	def unfinished_matches
		matches.select{|m| m.finished != 1}.sort_by{|m| m.bout_number}
	end

end
