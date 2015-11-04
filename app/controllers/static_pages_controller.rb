class StaticPagesController < ApplicationController
  before_filter :check_access, only: [:createCustomWeights,:generate_matches,:weigh_in]



	def results
		if params[:tournament]
	      @tournament = Tournament.find(params[:tournament])
		end
    if @tournament
    	@matches = @tournament.matches
    end
		@matches = @matches.where(finished: 1)
	end

	def brackets
	    if params[:weight]
	    	@weight = Weight.where(:id => params[:weight]).includes(:matches,:wrestlers,:tournament).first
	    	@tournament = @weight.tournament
	    	@matches = @weight.matches
	    	@wrestlers = @weight.wrestlers.includes(:school)
				if @matches.empty? or @wrestlers.empty?
					redirect_to "/static_pages/noMatches?tournament=#{@tournament.id}"
				else
					@pools = @weight.poolRounds(@matches)
					@bracketType = @weight.pool_bracket_type
				end
	    end
	end

	def all_brackets
	    if params[:tournament]
	    	@tournament = Tournament.find(params[:tournament])
	    end
	end


	def createCustomWeights
			@tournament = Tournament.find(params[:tournament])
		@custom = params[:customValue].to_s
			@tournament.createCustomWeights(@custom)

		redirect_to "/tournaments/#{@tournament.id}"
	end


	
	def weigh_in
		if params[:wrestler]
    		 Wrestler.update(params[:wrestler].keys, params[:wrestler].values)
    	end
		if params[:tournament]
	      @tournament = Tournament.where(:id => params[:tournament]).includes(:weights).first
	      @tournament_id = @tournament.id
	      @tournament_name = @tournament.name
		end
	    if @tournament
	    	@weights = @tournament.weights
	    	@weights = @weights.sort_by{|x|[x.max]}
	    end
	    if params[:weight]
	      @weight = Weight.where(:id => params[:weight]).includes(:tournament,:wrestlers).first
	      @tournament_id = @weight.tournament.id
	      @tournament_name = @weight.tournament.name
	      @tournament = @weight.tournament
	      @weights = @tournament.weights
		end
	    if @weight
	    	@wrestlers = @weight.wrestlers
	    	
	    end
	end


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
