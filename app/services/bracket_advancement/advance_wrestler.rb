class AdvanceWrestler
    def initialize( wrestler )
      @wrestler = wrestler
      @tournament = @wrestler.tournament
    end
    
    def advance
        PoolAdvance.new(@wrestler,@wrestler.last_match).advanceWrestler if @tournament.tournament_type == "Pool to bracket"
    end
    if Rails.env.production?
		handle_asynchronously :advance
    end
    
end