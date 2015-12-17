class Mat < ActiveRecord::Base
	belongs_to :tournament
	has_many :matches
	
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
	
	def cached_matches
		cache_timestamp = self.updated_at
	    cache_key = "matMatches|#{id}|#{cache_timestamp}"
	
	    Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
	      self.matches.includes(:wrestlers)
	    end
	end
	
	def assignNextMatch
		t_matches = tournament.matches.select{|m| m.mat_id == nil}
		if t_matches.size > 0
			match = t_matches.sort_by{|m| m.bout_number}.first
			match.mat_id = self.id
			match.save
		end
	end
	
	def unfinishedMatches
		cached_matches.select{|m| m.finished == nil}.sort_by{|m| m.bout_number}
	end
	
end
