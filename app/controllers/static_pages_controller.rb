class StaticPagesController < ApplicationController

	def my_tournaments
		@tournaments = current_user.tournaments
	end

	def not_allowed
	end

	def about
		
	end
end
