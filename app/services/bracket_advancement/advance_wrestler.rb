require "set"

class BracketAdvancement::AdvanceWrestler
    def initialize(wrestler, last_match)
      @wrestler = wrestler
      @last_match = last_match
    end
    
    def advance
      AdvanceWrestlerJob.perform_later([@last_match.id], @wrestler.tournament.id)
    end

    def advance_raw(tracker: nil, invalidate: true, context: nil, reload: true)
      @last_match = Match.find_by(id: @last_match&.id) if reload
      @wrestler = Wrestler.find_by(id: @wrestler.id) if reload
      return tracker unless @last_match && @wrestler && @last_match.finished?

      tracker ||= { processed: Set.new, weight_ids: Set.new, wrestler_ids: Set.new, contexts: {} }
      tracker[:contexts] ||= {}
      context ||= tracker[:contexts][@wrestler.weight_id] ||= preload_advancement_context
      @last_match = context[:matches_by_id][@last_match.id] || @last_match
      @wrestler = context[:wrestlers_by_id][@wrestler.id] || @wrestler
      @tournament = context[:weight].tournament
      processing_key = [@last_match.id, @wrestler.id]
      return tracker if tracker[:processed].include?(processing_key)

      tracker[:processed] << processing_key

      matches_to_advance = []

      if @tournament.tournament_type == "Pool to bracket"
        matches_to_advance.concat(pool_to_bracket_advancement(context))
      elsif @tournament.tournament_type.include?("Modified 16 Man Double Elimination")
        service = BracketAdvancement::ModifiedDoubleEliminationAdvance.new(@wrestler, @last_match, matches: context[:matches])
        service.bracket_advancement
        matches_to_advance.concat(service.matches_to_advance)
      elsif @tournament.tournament_type.include?("Regular Double Elimination")
        service = BracketAdvancement::DoubleEliminationAdvance.new(@wrestler, @last_match, matches: context[:matches])
        service.bracket_advancement
        matches_to_advance.concat(service.matches_to_advance)
      end

      changed_wrestler_ids = persist_advancement_changes(context)
      tracker[:weight_ids] << context[:weight].id
      tracker[:wrestler_ids].merge(changed_wrestler_ids | [@wrestler.id])
      advance_pending_matches(matches_to_advance, tracker, context)
      TournamentCacheInvalidator.advancement_completed(tracker[:weight_ids].to_a, tracker[:wrestler_ids].to_a) if invalidate
      tracker
    end
    
    def preload_advancement_context
      weight = Weight.includes(
        :tournament,
        { matches: [:wrestler1, :wrestler2, :winner] },
        {
          wrestlers: [
            :school,
            :deductedPoints,
            { weight: :tournament },
            { matches_as_w1: :winner },
            { matches_as_w2: :winner }
          ]
        }
      ).find(@wrestler.weight_id)
      matches = weight.matches.to_a
      wrestlers = weight.wrestlers.to_a
      {
        weight: weight,
        matches: matches,
        matches_by_id: matches.index_by(&:id),
        wrestlers: wrestlers,
        wrestlers_by_id: wrestlers.index_by(&:id)
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
          finalized_at: m.finished == 1 ? (m.finalized_at || timestamp) : m.finalized_at,
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
      updates.map { |row| row[:id] }
    end

    def advance_pending_matches(matches_to_advance, tracker, context)
      matches_to_advance.uniq(&:id).each do |match|
        current_match = context[:matches_by_id][match.id] || Match.find_by(id: match.id)
        next unless current_match

        [current_match.w1, current_match.w2].compact.uniq.each do |wrestler_id|
          wrestler = context[:wrestlers_by_id][wrestler_id] || Wrestler.find_by(id: wrestler_id)
          BracketAdvancement::AdvanceWrestler.new(wrestler, current_match).advance_raw(tracker:, invalidate: false, context:) if wrestler
        end
      end
    end

    def pool_to_bracket_advancement(context)
      matches_to_advance = []
      wrestlers_in_pool = context[:wrestlers].select { |w| w.pool == @wrestler.pool }
      if @wrestler.weight.all_pool_matches_finished(@wrestler.pool) && (@wrestler.finished_bracket_matches.size < 1)
        BracketAdvancement::PoolOrder.new(wrestlers_in_pool).getPoolOrder
      end
      service = BracketAdvancement::PoolAdvance.new(@wrestler, @last_match, matches: context[:matches], wrestlers: context[:wrestlers])
      service.advanceWrestler
      matches_to_advance.concat(service.matches_to_advance)
      matches_to_advance
    end

end
