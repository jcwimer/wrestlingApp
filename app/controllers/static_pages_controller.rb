class StaticPagesController < ApplicationController

	def index
	end

	def school
		@school = School.all
	end
	
end
