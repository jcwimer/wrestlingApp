class AdvanceWrestler
    def initialize( wrestler )
      @wrestler = wrestler
      @tournament = @wrestler.tournament
    end
    
    def advance
        PoolAdvance.new(@wrestler,@wrestler.lastMatch).advanceWrestler if @tournament.tournament_type == "Pool to bracket"
    end
    if Rails.env.production?
		handle_asynchronously :advance
    end
    
end