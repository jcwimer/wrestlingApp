class StaticPagesController < ApplicationController

	def index
		@tournaments = Tournament.all
	end
	def up_matches
		if params[:tournament]
	      @tournament = Tournament.find(params[:tournament])
	    end
	    if @tournament
	    	@matches = Match.where(tournament_id: @tournament.id)
	    end
		@matches = @matches.where(finished: nil)

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
	    	@matches_all = Match.where(tournament_id: @tournament.id)
	    	@matches_all.each do |match|
	    		match.destroy
	    	end
	    	@weights = Weight.where(tournament_id: @tournament.id)
	    	#ROUND 1
	    	@weights.order("id asc").each do |weight|
	    		@seed1 = Wrestler.where(weight_id: weight.id, original_seed: 1).first
		    	@seed10 = Wrestler.where(weight_id: weight.id, original_seed: 10).first
		    	@seed7 = Wrestler.where(weight_id: weight.id, original_seed: 7).first
		    	@seed5 = Wrestler.where(weight_id: weight.id, original_seed: 5).first
		    	@seed4 = Wrestler.where(weight_id: weight.id, original_seed: 4).first
		    	@seed2 = Wrestler.where(weight_id: weight.id, original_seed: 2).first
		    	@seed9 = Wrestler.where(weight_id: weight.id, original_seed: 9).first
		    	@seed6 = Wrestler.where(weight_id: weight.id, original_seed: 6).first
		    	@seed8 = Wrestler.where(weight_id: weight.id, original_seed: 8).first
		    	@seed3 = Wrestler.where(weight_id: weight.id, original_seed: 3).first
		    	@seed11 = Wrestler.where(weight_id: @weight.id, original_seed: 11).first
		    	@seed12 = Wrestler.where(weight_id: @weight.id, original_seed: 12).first
		    	@seed13 = Wrestler.where(weight_id: @weight.id, original_seed: 13).first
		    	@seed14 = Wrestler.where(weight_id: @weight.id, original_seed: 14).first
		    	@seed15 = Wrestler.where(weight_id: @weight.id, original_seed: 15).first
		    	@seed16 = Wrestler.where(weight_id: @weight.id, original_seed: 16).first
		    	@bracket_size = Wrestler.where(weight_id: weight.id).count
		    	def createMatch(r_id,g_id,tournament)
		    		@match = Match.new
		    		@match.r_id = r_id
		    		@match.g_id = g_id
		    		@match.tournament_id = tournament
		    		@match.round = 1
		    		@match.save
		    	end
		    	if @bracket_size == 16
		    		createMatch(@seed1.id,@seed16.id,@tournament.id)
		    		createMatch(@seed12.id,@seed8.id,@tournament.id)
		    		createMatch(@seed2.id,@seed15.id,@tournament.id)
		    		createMatch(@seed11.id,@seed7.id,@tournament.id)
		    		createMatch(@seed3.id,@seed14.id,@tournament.id)
		    		createMatch(@seed10.id,@seed6.id,@tournament.id)
		    		createMatch(@seed4.id,@seed13.id,@tournament.id)
		    		createMatch(@seed9.id,@seed5.id,@tournament.id)
		    	elsif @bracket_size == 10
		    		createMatch(@seed1.id,@seed10.id,@tournament.id)
		    		createMatch(@seed5.id,@seed7.id,@tournament.id)
		    		createMatch(@seed2.id,@seed9.id,@tournament.id)
		    		createMatch(@seed6.id,@seed8.id,@tournament.id)
		    	elsif @bracket_size == 9
		    		createMatch(@seed1.id,@seed9.id,@tournament.id)
		    		createMatch(@seed5.id,@seed7.id,@tournament.id)
		    		createMatch(@seed6.id,@seed8.id,@tournament.id)
		    	elsif @bracket_size == 8
		    		createMatch(@seed5.id,@seed7.id,@tournament.id)
		    		createMatch(@seed6.id,@seed8.id,@tournament.id)
		    	elsif @bracket_size == 7
		    		createMatch(@seed5.id,@seed7.id,@tournament.id)
		    	end

		    end
		    #ROUND 2
	    	@weights.order("id asc").each do |weight|
	    		@seed1 = Wrestler.where(weight_id: weight.id, original_seed: 1).first
		    	@seed10 = Wrestler.where(weight_id: weight.id, original_seed: 10).first
		    	@seed7 = Wrestler.where(weight_id: weight.id, original_seed: 7).first
		    	@seed5 = Wrestler.where(weight_id: weight.id, original_seed: 5).first
		    	@seed4 = Wrestler.where(weight_id: weight.id, original_seed: 4).first
		    	@seed2 = Wrestler.where(weight_id: weight.id, original_seed: 2).first
		    	@seed9 = Wrestler.where(weight_id: weight.id, original_seed: 9).first
		    	@seed6 = Wrestler.where(weight_id: weight.id, original_seed: 6).first
		    	@seed8 = Wrestler.where(weight_id: weight.id, original_seed: 8).first
		    	@seed3 = Wrestler.where(weight_id: weight.id, original_seed: 3).first
		    	@seed12 = Wrestler.where(weight_id: @weight.id, original_seed: 12).first
		    	@seed13 = Wrestler.where(weight_id: @weight.id, original_seed: 13).first
		    	@seed14 = Wrestler.where(weight_id: @weight.id, original_seed: 14).first
		    	@seed15 = Wrestler.where(weight_id: @weight.id, original_seed: 15).first
		    	@seed16 = Wrestler.where(weight_id: @weight.id, original_seed: 16).first
		    	@bracket_size = Wrestler.where(weight_id: weight.id).count
		    	def createMatch(r_id,g_id,tournament)
		    		@match = Match.new
		    		@match.r_id = r_id
		    		@match.g_id = g_id
		    		@match.tournament_id = tournament
		    		@match.round = 2
		    		@match.save
		    	end
		    	if @bracket_size == 16
		    		createMatch(@seed1.id,@seed12.id,@tournament.id)
		    		createMatch(@seed16.id,@seed8.id,@tournament.id)
		    		createMatch(@seed2.id,@seed11.id,@tournament.id)
		    		createMatch(@seed15.id,@seed7.id,@tournament.id)
		    		createMatch(@seed3.id,@seed10.id,@tournament.id)
		    		createMatch(@seed14.id,@seed6.id,@tournament.id)
		    		createMatch(@seed4.id,@seed9.id,@tournament.id)
		    		createMatch(@seed13.id,@seed5.id,@tournament.id)
		    	elsif @bracket_size == 10
		    		createMatch(@seed1.id,@seed5.id,@tournament.id)
		    		createMatch(@seed10.id,@seed4.id,@tournament.id)
		    		createMatch(@seed2.id,@seed6.id,@tournament.id)
		    		createMatch(@seed9.id,@seed3.id,@tournament.id)
		    	elsif @bracket_size == 9
		    		createMatch(@seed1.id,@seed5.id,@tournament.id)
		    		createMatch(@seed9.id,@seed4.id,@tournament.id)
		    		createMatch(@seed2.id,@seed6.id,@tournament.id)
		    	elsif @bracket_size == 8
		    		createMatch(@seed1.id,@seed5.id,@tournament.id)
		    		createMatch(@seed2.id,@seed6.id,@tournament.id)
		    	elsif @bracket_size == 7
		    		createMatch(@seed1.id,@seed5.id,@tournament.id)
		    		createMatch(@seed2.id,@seed6.id,@tournament.id)
		    	end

		    end
		    #ROUND 3
	    	@weights.order("id asc").each do |weight|
	    		@seed1 = Wrestler.where(weight_id: weight.id, original_seed: 1).first
		    	@seed10 = Wrestler.where(weight_id: weight.id, original_seed: 10).first
		    	@seed7 = Wrestler.where(weight_id: weight.id, original_seed: 7).first
		    	@seed5 = Wrestler.where(weight_id: weight.id, original_seed: 5).first
		    	@seed4 = Wrestler.where(weight_id: weight.id, original_seed: 4).first
		    	@seed2 = Wrestler.where(weight_id: weight.id, original_seed: 2).first
		    	@seed9 = Wrestler.where(weight_id: weight.id, original_seed: 9).first
		    	@seed6 = Wrestler.where(weight_id: weight.id, original_seed: 6).first
		    	@seed8 = Wrestler.where(weight_id: weight.id, original_seed: 8).first
		    	@seed3 = Wrestler.where(weight_id: weight.id, original_seed: 3).first
		    	@seed12 = Wrestler.where(weight_id: @weight.id, original_seed: 12).first
		    	@seed13 = Wrestler.where(weight_id: @weight.id, original_seed: 13).first
		    	@seed14 = Wrestler.where(weight_id: @weight.id, original_seed: 14).first
		    	@seed15 = Wrestler.where(weight_id: @weight.id, original_seed: 15).first
		    	@seed16 = Wrestler.where(weight_id: @weight.id, original_seed: 16).first
		    	@bracket_size = Wrestler.where(weight_id: weight.id).count
		    	def createMatch(r_id,g_id,tournament)
		    		@match = Match.new
		    		@match.r_id = r_id
		    		@match.g_id = g_id
		    		@match.tournament_id = tournament
		    		@match.round = 3
		    		@match.save
		    	end
		    	if @bracket_size == 16
		    		createMatch(@seed1.id,@seed8.id,@tournament.id)
		    		createMatch(@seed12.id,@seed16.id,@tournament.id)
		    		createMatch(@seed2.id,@seed7.id,@tournament.id)
		    		createMatch(@seed11.id,@seed15.id,@tournament.id)
		    		createMatch(@seed3.id,@seed6.id,@tournament.id)
		    		createMatch(@seed10.id,@seed14.id,@tournament.id)
		    		createMatch(@seed4.id,@seed5.id,@tournament.id)
		    		createMatch(@seed9.id,@seed13.id,@tournament.id)
		    	elsif @bracket_size == 10
		    		createMatch(@seed1.id,@seed4.id,@tournament.id)
		    		createMatch(@seed10.id,@seed7.id,@tournament.id)
		    		createMatch(@seed2.id,@seed3.id,@tournament.id)
		    		createMatch(@seed8.id,@seed9.id,@tournament.id)
		    	elsif @bracket_size == 9
		    		createMatch(@seed1.id,@seed4.id,@tournament.id)
		    		createMatch(@seed9.id,@seed7.id,@tournament.id)
		    		createMatch(@seed2.id,@seed3.id,@tournament.id)
		    	elsif @bracket_size == 8
		    		createMatch(@seed1.id,@seed4.id,@tournament.id)
		    		createMatch(@seed2.id,@seed3.id,@tournament.id)
		    	elsif @bracket_size == 7
		    		createMatch(@seed1.id,@seed4.id,@tournament.id)
		    		createMatch(@seed2.id,@seed3.id,@tournament.id)
		    	end

		    end
		    #ROUND 4
	    	@weights.order("id asc").each do |weight|
	    		@seed1 = Wrestler.where(weight_id: weight.id, original_seed: 1).first
		    	@seed10 = Wrestler.where(weight_id: weight.id, original_seed: 10).first
		    	@seed7 = Wrestler.where(weight_id: weight.id, original_seed: 7).first
		    	@seed5 = Wrestler.where(weight_id: weight.id, original_seed: 5).first
		    	@seed4 = Wrestler.where(weight_id: weight.id, original_seed: 4).first
		    	@seed2 = Wrestler.where(weight_id: weight.id, original_seed: 2).first
		    	@seed9 = Wrestler.where(weight_id: weight.id, original_seed: 9).first
		    	@seed6 = Wrestler.where(weight_id: weight.id, original_seed: 6).first
		    	@seed8 = Wrestler.where(weight_id: weight.id, original_seed: 8).first
		    	@seed3 = Wrestler.where(weight_id: weight.id, original_seed: 3).first
		    	@bracket_size = Wrestler.where(weight_id: weight.id).count
		    	def createMatch(r_id,g_id,tournament)
		    		@match = Match.new
		    		@match.r_id = r_id
		    		@match.g_id = g_id
		    		@match.tournament_id = tournament
		    		@match.round = 4
		    		@match.save
		    	end
		    	if @bracket_size == 10
		    		createMatch(@seed1.id,@seed7.id,@tournament.id)
		    		createMatch(@seed5.id,@seed4.id,@tournament.id)
		    		createMatch(@seed2.id,@seed8.id,@tournament.id)
		    		createMatch(@seed6.id,@seed3.id,@tournament.id)
		    	elsif @bracket_size == 9
		    		createMatch(@seed1.id,@seed7.id,@tournament.id)
		    		createMatch(@seed5.id,@seed4.id,@tournament.id)
		    		createMatch(@seed2.id,@seed8.id,@tournament.id)
		    		createMatch(@seed6.id,@seed3.id,@tournament.id)
		    	elsif @bracket_size == 8
		    		createMatch(@seed1.id,@seed7.id,@tournament.id)
		    		createMatch(@seed5.id,@seed4.id,@tournament.id)
		    		createMatch(@seed2.id,@seed8.id,@tournament.id)
		    		createMatch(@seed6.id,@seed3.id,@tournament.id)
		    	elsif @bracket_size == 7
		    		createMatch(@seed1.id,@seed7.id,@tournament.id)
		    		createMatch(@seed5.id,@seed4.id,@tournament.id)
		    		createMatch(@seed6.id,@seed3.id,@tournament.id)
		    	end

		    end
		    #ROUND 5
	    	@weights.order("id asc").each do |weight|
	    		@seed1 = Wrestler.where(weight_id: weight.id, original_seed: 1).first
		    	@seed10 = Wrestler.where(weight_id: weight.id, original_seed: 10).first
		    	@seed7 = Wrestler.where(weight_id: weight.id, original_seed: 7).first
		    	@seed5 = Wrestler.where(weight_id: weight.id, original_seed: 5).first
		    	@seed4 = Wrestler.where(weight_id: weight.id, original_seed: 4).first
		    	@seed2 = Wrestler.where(weight_id: weight.id, original_seed: 2).first
		    	@seed9 = Wrestler.where(weight_id: weight.id, original_seed: 9).first
		    	@seed6 = Wrestler.where(weight_id: weight.id, original_seed: 6).first
		    	@seed8 = Wrestler.where(weight_id: weight.id, original_seed: 8).first
		    	@seed3 = Wrestler.where(weight_id: weight.id, original_seed: 3).first
		    	@bracket_size = Wrestler.where(weight_id: weight.id).count
		    	def createMatch(r_id,g_id,tournament)
		    		@match = Match.new
		    		@match.r_id = r_id
		    		@match.g_id = g_id
		    		@match.tournament_id = tournament
		    		@match.round = 5
		    		@match.save
		    	end
		    	if @bracket_size == 10
		    		createMatch(@seed10.id,@seed5.id,@tournament.id)
		    		createMatch(@seed7.id,@seed4.id,@tournament.id)
		    		createMatch(@seed9.id,@seed6.id,@tournament.id)
		    		createMatch(@seed8.id,@seed3.id,@tournament.id)
		    	elsif @bracket_size == 9
		    		createMatch(@seed7.id,@seed4.id,@tournament.id)
		    		createMatch(@seed9.id,@seed5.id,@tournament.id)
		    		createMatch(@seed8.id,@seed3.id,@tournament.id)
		    	elsif @bracket_size == 8
		    		createMatch(@seed7.id,@seed4.id,@tournament.id)
		    		createMatch(@seed8.id,@seed3.id,@tournament.id)
		    	elsif @bracket_size == 7
		    		createMatch(@seed7.id,@seed4.id,@tournament.id)
		    	end

		    end
	    end

	end

	
	






end
