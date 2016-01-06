class StaticPagesController < ApplicationController

	def my_tournaments
		tournaments_created = current_user.tournaments
		tournaments_delegated = current_user.delegated_tournaments
		all_tournaments = tournaments_created + tournaments_delegated
		@tournaments = all_tournaments.sort_by{|t| t.daysUntil}
	end

	def not_allowed
	end

	def about
		
	end
end
