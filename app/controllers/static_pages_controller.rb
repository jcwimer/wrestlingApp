class StaticPagesController < ApplicationController
  before_filter :check_access, only: [:weigh_in]



	def not_allowed
	end

	private
	def check_access
	  if params[:tournament]
	     @tournament = Tournament.find(params[:tournament])
	     if current_user != @tournament.user
		redirect_to '/static_pages/not_allowed'
	     end	
	  end
	end
end
