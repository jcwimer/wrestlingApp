class StaticPagesController < ApplicationController

	def my_tournaments
		tournaments_created = current_user.tournaments.to_a
		tournaments_delegated = current_user.delegated_tournaments.to_a
		all_tournaments = tournaments_created + tournaments_delegated
		@tournaments = all_tournaments.sort_by{|t| t.days_until_start}
		@schools = current_user.delegated_schools.includes(:tournament)
	end

	def not_allowed
	end

	def about
		
	end
	
	def tutorials
	end
end
