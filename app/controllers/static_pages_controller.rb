class StaticPagesController < ApplicationController

	def index
		@tournaments = Tournament.all
	end

	def brackets
	    if params[:weight]
	    	@weight = Weight.find(params[:weight])
	    	@tournament = Tournament.find(@weight.tournament_id)
	    	@wrestlers = Wrestler.where(weight_id: @weight.id)
	    	@bracket_size = Wrestler.where(weight_id: @weight.id).count
	    	@seed1 = Wrestler.where(weight_id: @weight.id, original_seed: 1).first
	    	@seed10 = Wrestler.where(weight_id: @weight.id, original_seed: 10).first
	    	@seed7 = Wrestler.where(weight_id: @weight.id, original_seed: 7).first
	    	@seed5 = Wrestler.where(weight_id: @weight.id, original_seed: 5).first
	    	@seed4 = Wrestler.where(weight_id: @weight.id, original_seed: 4).first
	    	@seed2 = Wrestler.where(weight_id: @weight.id, original_seed: 2).first
	    	@seed9 = Wrestler.where(weight_id: @weight.id, original_seed: 9).first
	    	@seed6 = Wrestler.where(weight_id: @weight.id, original_seed: 6).first
	    	@seed8 = Wrestler.where(weight_id: @weight.id, original_seed: 8).first
	    	@seed3 = Wrestler.where(weight_id: @weight.id, original_seed: 3).first
	    end


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
