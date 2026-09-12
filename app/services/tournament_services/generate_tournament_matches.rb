# frozen_string_literal: true

module TournamentServices
  class GenerateTournamentMatches
    def initialize(tournament)
      @tournament = tournament
    end

    def generate
      # Use perform_later which will execute based on centralized adapter config
      GenerateTournamentMatchesJob.perform_later_with_enqueue_retry(@tournament)
    end

    def generate_raw
      standard_starting_actions
      generation_context = preload_generation_context
      seed_wrestlers_in_memory(generation_context)
      match_rows = build_match_rows(generation_context)
      post_process_match_rows_in_memory(generation_context, match_rows)
      persist_generation_rows(generation_context, match_rows)
      post_match_creation_actions
      advance_bye_matches_after_insert
      TournamentCacheInvalidator.generation_completed(@tournament.id)
    end

    def standard_starting_actions
      @tournament.curently_generating_matches = 1
      @tournament.save
      TournamentServices::WipeTournamentMatches.new(@tournament).set_up_match_generation
    end

    def preload_generation_context
      weights = @tournament.weights.includes(:wrestlers).order(:max).to_a
      wrestlers = weights.flat_map(&:wrestlers)
      {
        weights: weights,
        wrestlers: wrestlers,
        wrestlers_by_weight_id: wrestlers.group_by(&:weight_id)
      }
    end

    def seed_wrestlers_in_memory(generation_context)
      TournamentServices::TournamentSeeding.new(@tournament).set_seeds(weights: generation_context[:weights],
                                                                       persist: false)
    end

    def build_match_rows(generation_context)
      if @tournament.tournament_type == 'Pool to bracket'
        return TournamentServices::PoolToBracketMatchGeneration.new(
          @tournament,
          weights: generation_context[:weights],
          wrestlers_by_weight_id: generation_context[:wrestlers_by_weight_id]
        ).generate_pool_to_bracket_matches
      end

      if @tournament.tournament_type.include? 'Modified 16 Man Double Elimination'
        return TournamentServices::ModifiedSixteenManMatchGeneration.new(@tournament,
                                                                         weights: generation_context[:weights]).generate_matches
      end

      if @tournament.tournament_type.include? 'Regular Double Elimination'
        return TournamentServices::DoubleEliminationMatchGeneration.new(@tournament,
                                                                        weights: generation_context[:weights]).generate_matches
      end

      []
    end

    def persist_generation_rows(generation_context, match_rows)
      persist_wrestlers(generation_context[:wrestlers])
      persist_matches(match_rows)
    end

    def post_process_match_rows_in_memory(generation_context, match_rows)
      move_finals_rows_to_last_round(match_rows) unless @tournament.tournament_type.include?('Regular Double Elimination')
      assign_bouts_in_memory(match_rows, generation_context[:weights])
      assign_loser_names_in_memory(generation_context, match_rows)
      assign_bye_outcomes_in_memory(generation_context, match_rows)
    end

    def persist_wrestlers(wrestlers)
      return if wrestlers.blank?

      timestamp = Time.current
      rows = wrestlers.map do |w|
        {
          id: w.id,
          bracket_line: w.bracket_line,
          pool: w.pool,
          updated_at: timestamp
        }
      end
      Wrestler.upsert_all(rows)
    end

    def persist_matches(match_rows)
      return if match_rows.blank?

      timestamp = Time.current
      rows_with_timestamps = match_rows.map do |row|
        row.to_h.symbolize_keys.merge(created_at: timestamp, updated_at: timestamp)
      end

      all_keys = rows_with_timestamps.flat_map(&:keys).uniq
      normalized_rows = rows_with_timestamps.map do |row|
        all_keys.index_with { |key| row[key] }
      end

      Match.insert_all!(normalized_rows)
    end

    def post_match_creation_actions
      @tournament.reset_and_fill_bout_board
      @tournament.curently_generating_matches = nil
      @tournament.save!
      Tournament.broadcast_up_matches_board(@tournament.id)
    end

    FINALS_BRACKET_POSITIONS = ['1/2', '3/4', '5/6', '7/8'].freeze

    def move_finals_rows_to_last_round(match_rows)
      finals_round = match_rows.pluck(:round).compact.max
      return unless finals_round

      match_rows.each do |row|
        row[:round] = finals_round if FINALS_BRACKET_POSITIONS.include?(row[:bracket_position])
      end
    end

    def assign_bouts_in_memory(match_rows, weights)
      bout_counts = Hash.new(0)
      weight_max_by_id = weights.to_h { |w| [w.id, w.max] }

      match_rows
        .sort_by do |row|
        [row[:round].to_i, weight_max_by_id[row[:weight_id]].to_f, row[:weight_id].to_i,
         row[:bracket_position_number].to_i]
      end
        .each do |row|
          round = row[:round].to_i
          row[:bout_number] = (round * 1000) + bout_counts[round]
          bout_counts[round] += 1
        end
    end

    def assign_loser_names_in_memory(generation_context, match_rows)
      if @tournament.tournament_type == 'Pool to bracket'
        service = TournamentServices::PoolToBracketGenerateLoserNames.new(@tournament)
        generation_context[:weights].each { |weight| service.assign_loser_names_in_memory(weight, match_rows) }
      elsif @tournament.tournament_type.include?('Modified 16 Man Double Elimination')
        service = TournamentServices::ModifiedSixteenManGenerateLoserNames.new(@tournament)
        generation_context[:weights].each { |weight| service.assign_loser_names_in_memory(weight, match_rows) }
      elsif @tournament.tournament_type.include?('Regular Double Elimination')
        service = TournamentServices::DoubleEliminationGenerateLoserNames.new(@tournament)
        generation_context[:weights].each { |weight| service.assign_loser_names_in_memory(weight, match_rows) }
      end
    end

    def assign_bye_outcomes_in_memory(generation_context, match_rows)
      if @tournament.tournament_type.include?('Modified 16 Man Double Elimination')
        service = TournamentServices::ModifiedSixteenManGenerateLoserNames.new(@tournament)
        generation_context[:weights].each { |weight| service.assign_bye_outcomes_in_memory(weight, match_rows) }
      elsif @tournament.tournament_type.include?('Regular Double Elimination')
        service = TournamentServices::DoubleEliminationGenerateLoserNames.new(@tournament)
        generation_context[:weights].each { |weight| service.assign_bye_outcomes_in_memory(weight, match_rows) }
      end
    end

    def advance_bye_matches_after_insert
      match_ids = Match.where(tournament_id: @tournament.id, finished: 1, win_type: 'BYE')
                       .where.not(winner_id: nil)
                       .pluck(:id)
      return unless match_ids.any?

      AdvanceWrestlerJob.perform_now(match_ids, @tournament.id)
      FillBoutBoardJob.perform_now(@tournament.id)
    end

    def assign_bouts
      bout_counts = Hash.new(0)
      timestamp = Time.current
      ordered_matches = Match.joins(:weight)
                             .where(tournament_id: @tournament.id)
                             .order('matches.round ASC, weights.max ASC, matches.id ASC')
                             .pluck('matches.id', 'matches.round')

      updates = []
      ordered_matches.each do |match_id, round|
        updates << {
          id: match_id,
          bout_number: (round * 1000) + bout_counts[round],
          updated_at: timestamp
        }
        bout_counts[round] += 1
      end

      Match.upsert_all(updates) if updates.any?
    end

    def move_finals_matches_to_last_round
      finals_round = @tournament.reload.total_rounds
      @tournament.matches
                 .where(bracket_position: ['1/2', '3/4', '5/6', '7/8'])
                 .update_all(round: finals_round, updated_at: Time.current)
    end

    def un_assign_mats
      @tournament.matches.update_all(mat_id: nil, updated_at: Time.current)
    end

    def un_assign_bouts
      @tournament.matches.update_all(bout_number: nil, updated_at: Time.current)
    end
  end
end
