class AdvanceWrestler
    def initialize( wrestler )
      @wrestler = wrestler
      @tournament = @wrestler.tournament
    end
    
    def advance
      pool_to_bracket_advancement if @tournament.tournament_type == "Pool to bracket"
    end
    if Rails.env.production?
		handle_asynchronously :advance
    end
    
    def pool_to_bracket_advancement
      if @wrestler.weight.all_pool_matches_finished(@wrestler.pool) and (@wrestler.finished_bracket_matches.size == 0 or @wrestler.weight.pools == 1)
        PoolOrder.new(@wrestler.weight.wrestlers_in_pool(@wrestler.pool)).getPoolOrder
      end
      PoolAdvance.new(@wrestler,@wrestler.last_match).advanceWrestler
    end

end