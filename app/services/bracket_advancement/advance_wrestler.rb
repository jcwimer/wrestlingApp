class AdvanceWrestler
    def initialize( wrestler )
      @wrestler = wrestler
      @tournament = @wrestler.tournament
    end
    
    def advance
      if Rails.env.production?
          self.delay(:job_owner_id => @tournament.id, :job_owner_type => "Advance wrestler #{@wrestler.name} in the bracket").advance_raw
      else
          advance_raw
      end
    end

    def advance_raw
        pool_to_bracket_advancement if @tournament.tournament_type == "Pool to bracket"
    end
    
    def pool_to_bracket_advancement
      if @wrestler.weight.all_pool_matches_finished(@wrestler.pool) and (@wrestler.finished_bracket_matches.size == 0 or @wrestler.weight.pools == 1)
        PoolOrder.new(@wrestler.weight.wrestlers_in_pool(@wrestler.pool)).getPoolOrder
      end
      if @wrestler.weight.all_pool_matches_finished(@wrestler.pool)
        PoolAdvance.new(@wrestler,@wrestler.last_match).advanceWrestler
      end
    end

end