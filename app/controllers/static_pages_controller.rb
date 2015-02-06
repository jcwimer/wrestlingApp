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

	def team_scores
		if params[:tournament]
	      @tournament = Tournament.find(params[:tournament])
	    end
	    if @tournament
	    	@schools = School.where(tournament_id: @tournament.id)
	    	@schools.sort_by{|x|[x.score]}
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
	    	@poolOneWrestlers = Wrestler.where(weight_id: @weight.id, poolNumber: 1)
	    	@poolTwoWrestlers = Wrestler.where(weight_id: @weight.id, poolNumber: 2)
	    	@poolThreeWrestlers = Wrestler.where(weight_id: @weight.id, poolNumber: 3)
	    	@poolFourWrestlers = Wrestler.where(weight_id: @weight.id, poolNumber: 4)
	    end


	end

	def weights
		if params[:tournament]
	      @tournament = Tournament.find(params[:tournament])
	    end
	    if @tournament
	    	@weights = Weight.where(tournament_id: @tournament.id)
	    	@weights = @weights.sort_by{|x|[x.max]}
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
