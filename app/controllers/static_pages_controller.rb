class StaticPagesController < ApplicationController

	def index
		@tournaments = Tournament.all
	end
	def up_matches
		if params[:tournament]
	      @tournament = Tournament.find(params[:tournament])
	    end
	    if @tournament
	    	@matches = @tournament.upcomingMatches
	    end
	end
	def results
		if params[:tournament]
	      @tournament = Tournament.find(params[:tournament])
	    end
	    if @tournament
	    	@matches = Match.where(tournament_id: @tournament.id)
	    end
		@matches = @matches.where(finished: 1)

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
	    	@seed11 = Wrestler.where(weight_id: @weight.id, original_seed: 11).first
	    	@seed12 = Wrestler.where(weight_id: @weight.id, original_seed: 12).first
	    	@seed13 = Wrestler.where(weight_id: @weight.id, original_seed: 13).first
	    	@seed14 = Wrestler.where(weight_id: @weight.id, original_seed: 14).first
	    	@seed15 = Wrestler.where(weight_id: @weight.id, original_seed: 15).first
	    	@seed16 = Wrestler.where(weight_id: @weight.id, original_seed: 16).first
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

	def generate_matches
		if user_signed_in?
	    else
	      redirect_to root_path
	    end
		if params[:tournament]
	      @tournament = Tournament.find(params[:tournament])
	    end
	    if @tournament
	 		@tournament.generateMatches
	    end

	end

	
	






end
