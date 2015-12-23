class StaticPagesController < ApplicationController

	def my_tournaments
		@tournaments = current_user.tournaments.order('updated_at desc')
	end

	def not_allowed
	end

	def about
		
	end
end
