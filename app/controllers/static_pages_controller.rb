class StaticPagesController < ApplicationController

	def my_tournaments
		@tournaments = current_user.tournaments.sort_by{|t| t.daysUntil}
	end

	def not_allowed
	end

	def about
		
	end
end
