class StaticPagesController < ApplicationController

	def tournaments
		@tournaments = Tournament.all
	end
	def up_matches
		if params[:tournament]
	      @tournament = Tournament.find(params[:tournament])
		end
	    if @tournament
				@matches = @tournament.matches.where(mat_id: nil)
				@mats = @tournament.mats
				if @matches.empty?
					redirect_to "/static_pages/noMatches?tournament=#{@tournament.id}"
				end
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
    	@matches = @tournament.matches
    end
		@matches = @matches.where(finished: 1)
	end

	def brackets
	    if params[:weight]
	    	@weight = Weight.find(params[:weight])
	    	@tournament = Tournament.find(@weight.tournament_id)
	    	@matches = @tournament.matches.select{|m| m.weight_id == @weight.id}
	    	@wrestlers = Wrestler.where(weight_id: @weight.id).includes(:weight,:school)
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

	def weights
		if params[:tournament]
	      @tournament = Tournament.find(params[:tournament])
		end
	    if @tournament
	    	@weights = Weight.where(tournament_id: @tournament.id)
	    	@weights = @weights.sort_by{|x|[x.max]}
	    end
	end

	def createCustomWeights
			@tournament = Tournament.find(params[:tournament])
		if current_user != @tournament.user
			redirect_to root_path
		end  
		@custom = params[:customValue].to_s
			@tournament.createCustomWeights(@custom)

		redirect_to "/tournaments/#{@tournament.id}"
	end


	def noMatches
		if params[:tournament]
			@tournament = Tournament.find(params[:tournament])
		end
	end

	def generate_matches
		if !user_signed_in?
	      redirect_to root_path
	    elsif user_signed_in?
			if params[:tournament]
	      		@tournament = Tournament.find(params[:tournament])
			if current_user != @tournament.user
				redirect_to root_path
			end 	
			end
	    	if @tournament
	 			@tournament.generateMatchups
	    	end
		end
	end
	
	def weigh_in
		if !user_signed_in?
	      redirect_to root_path
	    end
		if params[:wrestler]
    		 Wrestler.update(params[:wrestler].keys, params[:wrestler].values)
    	end
		if params[:tournament]
	      @tournament = Tournament.find(params[:tournament])
	     if current_user != @tournament.user
			redirect_to root_path
		end  
	      @tournament_id = @tournament.id
	      @tournament_name = @tournament.name
		end
	    if @tournament
	    	@weights = Weight.where(tournament_id: @tournament.id)
	    	@weights = @weights.sort_by{|x|[x.max]}
	    end
	    if params[:weight]
	      @weight = Weight.find(params[:weight])
	      @tournament_id = @weight.tournament_id
	      @tournament_name = Tournament.find(@tournament_id).name
		end
	    if @weight
	    	@wrestlers = @weight.wrestlers
	    	
	    end
	end
end
