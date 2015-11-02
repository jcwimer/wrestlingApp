class Mat < ActiveRecord::Base
	belongs_to :tournament
	has_many :matches
	
	def assignNextMatch
		t_matches = tournament.matches.where(mat_id: nil)
		match = t_matches.order(:bout_number).first
		match.mat_id = self.id
		match.save
	end
	
	def unfinishedMatches
		matches.select{|m| m.finished == nil}.sort_by{|m| m.bout_number}
	end
	
end
