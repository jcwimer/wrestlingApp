class AdvanceWrestler
    def initialize( wrestler, last_match )
      @wrestler = wrestler
      @tournament = @wrestler.tournament
      @last_match = last_match
    end
    
    def advance
      if Rails.env.production?
          self.delay(:job_owner_id => @tournament.id, :job_owner_type => "Advance wrestler #{@wrestler.name} in the bracket").advance_raw
      else
          advance_raw
      end
    end

    def advance_raw
      @tournament.clear_errored_deferred_jobs
      if @last_match && @last_match.finished?
        pool_to_bracket_advancement if @tournament.tournament_type == "Pool to bracket"
        ModifiedDoubleEliminationAdvance.new(@wrestler, @last_match).bracket_advancement if @tournament.tournament_type.include? "Modified 16 Man Double Elimination"
        DoubleEliminationAdvance.new(@wrestler, @last_match).bracket_advancement if @tournament.tournament_type.include? "Regular Double Elimination"
      end
    end
    
    def pool_to_bracket_advancement
      if @wrestler.weight.all_pool_matches_finished(@wrestler.pool) and (@wrestler.finished_bracket_matches.size < 1)
        PoolOrder.new(@wrestler.weight.wrestlers_in_pool(@wrestler.pool)).getPoolOrder
      end
      PoolAdvance.new(@wrestler).advanceWrestler
    end

end