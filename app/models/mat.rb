class Mat < ActiveRecord::Base
	belongs_to :tournament
	has_many :matches
	
	validates :name, presence: true
	
	before_destroy do 
		if tournament.matches.size > 0
			tournament.resetMats
			matsToAssign = tournament.mats.select{|m| m.id != self.id}
			tournament.assignMats(matsToAssign)
		end
	end
	
	after_create do 
		if tournament.matches.size > 0
			tournament.resetMats
			matsToAssign = tournament.mats
			tournament.assignMats(matsToAssign)
		end
	end
	
	def assignNextMatch
		t_matches = tournament.matches.select{|m| m.mat_id == nil && m.finished != 1}
		if t_matches.size > 0
			match = t_matches.sort_by{|m| m.bout_number}.first
			match.mat_id = self.id
			match.save
		end
	end
	
	def unfinishedMatches
		matches.select{|m| m.finished != 1}.sort_by{|m| m.bout_number}
	end
	
end
