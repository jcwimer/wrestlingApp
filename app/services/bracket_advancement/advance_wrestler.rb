class AdvanceWrestler
    def initialize(wrestler, last_match)
      @wrestler = wrestler
      @tournament = @wrestler.tournament
      @last_match = last_match
    end
    
    def advance
      # Use perform_later which will execute based on centralized adapter config
      # This will be converted to inline execution in test environment by ActiveJob
      AdvanceWrestlerJob.perform_later(@wrestler, @last_match, @tournament.id)
    end

    def advance_raw
      @last_match = Match.find_by(id: @last_match&.id)
      @wrestler = Wrestler.includes(:school, :weight).find_by(id: @wrestler.id)
      return unless @last_match && @wrestler && @last_match.finished?

      context = preload_advancement_context
      matches_to_advance = []

      if @tournament.tournament_type == "Pool to bracket"
        matches_to_advance.concat(pool_to_bracket_advancement(context))
      elsif @tournament.tournament_type.include?("Modified 16 Man Double Elimination")
        service = ModifiedDoubleEliminationAdvance.new(@wrestler, @last_match, matches: context[:matches])
        service.bracket_advancement
        matches_to_advance.concat(service.matches_to_advance)
      elsif @tournament.tournament_type.include?("Regular Double Elimination")
        service = DoubleEliminationAdvance.new(@wrestler, @last_match, matches: context[:matches])
        service.bracket_advancement
        matches_to_advance.concat(service.matches_to_advance)
      end

      persist_advancement_changes(context)
      advance_pending_matches(matches_to_advance)
      @wrestler.school.calculate_score
    end
    
    def preload_advancement_context
      weight = Weight.includes(:matches, :wrestlers).find(@wrestler.weight_id)
      {
        weight: weight,
        matches: weight.matches.to_a,
        wrestlers: weight.wrestlers.to_a
      }
    end

    def persist_advancement_changes(context)
      persist_matches(context[:matches])
      persist_wrestlers(context[:wrestlers])
    end

    def persist_matches(matches)
      timestamp = Time.current
      updates = matches.filter_map do |m|
        next unless m.changed?

        {
          id: m.id,
          w1: m.w1,
          w2: m.w2,
          winner_id: m.winner_id,
          win_type: m.win_type,
          score: m.score,
          finished: m.finished,
          loser1_name: m.loser1_name,
          loser2_name: m.loser2_name,
          finished_at: m.finished_at,
          updated_at: timestamp
        }
      end
      Match.upsert_all(updates) if updates.any?
    end

    def persist_wrestlers(wrestlers)
      timestamp = Time.current
      updates = wrestlers.filter_map do |w|
        next unless w.changed?

        {
          id: w.id,
          pool_placement: w.pool_placement,
          pool_placement_tiebreaker: w.pool_placement_tiebreaker,
          updated_at: timestamp
        }
      end
      Wrestler.upsert_all(updates) if updates.any?
    end

    def advance_pending_matches(matches_to_advance)
      matches_to_advance.uniq(&:id).each do |match|
        match.advance_wrestlers
      end
    end

    def pool_to_bracket_advancement(context)
      matches_to_advance = []
      wrestlers_in_pool = context[:wrestlers].select { |w| w.pool == @wrestler.pool }
      if @wrestler.weight.all_pool_matches_finished(@wrestler.pool) && (@wrestler.finished_bracket_matches.size < 1)
        PoolOrder.new(wrestlers_in_pool).getPoolOrder
      end
      service = PoolAdvance.new(@wrestler, @last_match, matches: context[:matches], wrestlers: context[:wrestlers])
      service.advanceWrestler
      matches_to_advance.concat(service.matches_to_advance)
      matches_to_advance
    end

end
