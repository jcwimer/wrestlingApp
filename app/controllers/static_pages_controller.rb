class StaticPagesController < ApplicationController

	def index
		@tournaments = Tournament.all
	end

	def brackets
	    if params[:weight]
	    	@weight = Weight.find(params[:weight])
	    	@wrestlers = Wrestler.where(weight_id: @weight.id)
	    	@seed1 = Wrestler.where(weight_id: @weight.id, original_seed: 1).first
	    	@seed10 = Wrestler.where(weight_id: @weight.id, original_seed: 10).first
	    	@seed7 = Wrestler.where(weight_id: @weight.id, original_seed: 7).first
	    	@seed5 = Wrestler.where(weight_id: @weight.id, original_seed: 5).first
	    	@seed4 = Wrestler.where(weight_id: @weight.id, original_seed: 4).first
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
