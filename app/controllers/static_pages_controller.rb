class StaticPagesController < ApplicationController

	def index
		@tournaments = Tournament.all
	end

	def school
		@school = School.all
	end
	
end
