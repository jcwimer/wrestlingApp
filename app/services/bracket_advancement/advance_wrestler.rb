# frozen_string_literal: true

module BracketAdvancement
  class AdvanceWrestler
    def initialize(wrestler, last_match)
      @wrestler = wrestler
      @last_match = last_match
    end

    def advance
      AdvanceWrestlerJob.perform_later_with_enqueue_retry([@last_match.id], @last_match.tournament_id)
    end

    def advance_raw(tracker: nil, invalidate: true, context: nil, reload: true)
      @last_match = Match.find_by(id: @last_match&.id) if reload
      @wrestler = Wrestler.find_by(id: @wrestler&.id) if reload
      return tracker unless @last_match&.finished == 1 && (@wrestler || @last_match.double_bye?)

      tracker ||= { processed: Set.new, weight_ids: Set.new, wrestler_ids: Set.new, contexts: {} }
      tracker[:contexts] ||= {}
      context ||= tracker[:contexts][@last_match.weight_id] ||= preload_advancement_context
      @last_match = context[:matches_by_id][@last_match.id] || @last_match
      @wrestler = context[:wrestlers_by_id][@wrestler&.id] || @wrestler

      refresh_match_associations(context)
      @tournament = context[:weight].tournament
      processing_key = [@last_match.id, @wrestler&.id]
      return tracker if tracker[:processed].include?(processing_key)

      tracker[:processed] << processing_key

      if @tournament.tournament_type == 'Pool to bracket'
        pool_to_bracket_advancement(context) if @wrestler
      elsif @tournament.tournament_type.include?('Modified 16 Man Double Elimination')
        service = BracketAdvancement::ModifiedDoubleEliminationAdvance.new(@wrestler, @last_match,
                                                                           matches: context[:matches])
        service.bracket_advancement
      elsif @tournament.tournament_type.include?('Regular Double Elimination')
        service = BracketAdvancement::DoubleEliminationAdvance.new(@wrestler, @last_match, matches: context[:matches])
        service.bracket_advancement
      end

      changed_wrestler_ids = persist_advancement_changes(context)
      tracker[:weight_ids] << context[:weight].id
      tracker[:wrestler_ids].merge(changed_wrestler_ids | [@wrestler&.id].compact)
      if invalidate
        TournamentCacheInvalidator.advancement_completed(tracker[:weight_ids].to_a,
                                                         tracker[:wrestler_ids].to_a)
      end
      tracker
    end

    def preload_advancement_context
      weight = Weight.includes(
        :tournament,
        { matches: %i[wrestler1 wrestler2 winner] },
        {
          wrestlers: [
            :school,
            :deductedPoints,
            { weight: :tournament },
            { matches_as_w1: :winner },
            { matches_as_w2: :winner }
          ]
        }
      ).find(@last_match.weight_id)
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
      refresh_match_associations(context)
      persist_wrestlers(context[:wrestlers])
    end

    def refresh_match_associations(context)
      context[:matches].each { |match| match.winner = context[:wrestlers_by_id][match.winner_id] }
      context[:wrestlers].each do |wrestler|
        wrestler.association(:matches_as_w1).target = context[:matches].select { |match| match.w1 == wrestler.id }
        wrestler.association(:matches_as_w2).target = context[:matches].select { |match| match.w2 == wrestler.id }
      end
    end

    def persist_matches(matches)
      timestamp = Time.current
      updates = matches.filter_map do |m|
        next unless m.changed?

        {
          id: m.id,
          w1: m.w1,
          w2: m.w2,
          loser1_name: m.loser1_name,
          loser2_name: m.loser2_name,
          updated_at: timestamp
        }
      end
      Match.upsert_all(updates) if updates.any?
      matches.each(&:changes_applied)
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
      wrestlers.each(&:changes_applied)
      updates.pluck(:id)
    end

    def pool_to_bracket_advancement(context)
      wrestlers_in_pool = context[:wrestlers].select { |w| w.pool == @wrestler.pool }
      if @wrestler.weight.all_pool_matches_finished?(@wrestler.pool) && @wrestler.finished_bracket_matches.empty?
        BracketAdvancement::PoolOrder.new(wrestlers_in_pool).pool_order
      end
      service = BracketAdvancement::PoolAdvance.new(@wrestler, @last_match, matches: context[:matches],
                                                                            wrestlers: context[:wrestlers])
      service.advance_wrestler
    end
  end
end
