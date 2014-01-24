class StaticPagesController < ApplicationController

	def index
		@tournaments = Tournament.all
	end

	def brackets
	    if params[:weight]
	    	@weight = Weight.find(params[:weight])
	    	@wrestlers = Wrestler.where(weight_id: @weight.id)
	    	@seed1 = Wrestler.where(weight_id: @weight.id, original_seed: 1).first
	    end
	    #@seed1 = @wrestlers.where(original_seed: 1).name


	end

	def weights
		if params[:tournament]
	      @tournament = Tournament.find(params[:tournament])
	    end
	    if @tournament
	    	@weights = Weight.where(tournament_id: @tournament.id)
	    end
	end
	
end
