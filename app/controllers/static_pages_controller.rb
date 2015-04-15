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
	    	@bracketType = @weight.pool_bracket_type
	    	@tournament = Tournament.find(@weight.tournament_id)
	    	@matches = @tournament.upcomingMatches.select{|m| m.weight_id == @weight.id}
	    	@wrestlers = Wrestler.where(weight_id: @weight.id)
	    end
	end
	
	def all_brackets
	    if params[:tournament]
	    	@tournament = Tournament.find(params[:tournament])
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
end
