class GenerateTournamentMatches
    def initialize( tournament )
      @tournament = tournament
    end

    def generate
      # Use perform_later which will execute based on centralized adapter config
      GenerateTournamentMatchesJob.perform_later(@tournament)
    end

    def generate_raw
        standardStartingActions
        generation_context = preload_generation_context
        seed_wrestlers_in_memory(generation_context)
        match_rows = build_match_rows(generation_context)
        post_process_match_rows_in_memory(generation_context, match_rows)
        persist_generation_rows(generation_context, match_rows)
        postMatchCreationActions
        advance_bye_matches_after_insert
    end

    def standardStartingActions
        @tournament.curently_generating_matches = 1
        @tournament.save
        WipeTournamentMatches.new(@tournament).setUpMatchGeneration
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
      TournamentSeeding.new(@tournament).set_seeds(weights: generation_context[:weights], persist: false)
    end

    def build_match_rows(generation_context)
      return PoolToBracketMatchGeneration.new(
        @tournament,
        weights: generation_context[:weights],
        wrestlers_by_weight_id: generation_context[:wrestlers_by_weight_id]
      ).generatePoolToBracketMatches if @tournament.tournament_type == "Pool to bracket"

      return ModifiedSixteenManMatchGeneration.new(@tournament, weights: generation_context[:weights]).generate_matches if @tournament.tournament_type.include? "Modified 16 Man Double Elimination"

      return DoubleEliminationMatchGeneration.new(@tournament, weights: generation_context[:weights]).generate_matches if @tournament.tournament_type.include? "Regular Double Elimination"

      []
    end

    def persist_generation_rows(generation_context, match_rows)
      persist_wrestlers(generation_context[:wrestlers])
      persist_matches(match_rows)
    end

    def post_process_match_rows_in_memory(generation_context, match_rows)
      move_finals_rows_to_last_round(match_rows) unless @tournament.tournament_type.include?("Regular Double Elimination")
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
        all_keys.each_with_object({}) { |key, normalized| normalized[key] = row[key] }
      end

      Match.insert_all!(normalized_rows)
    end

    def postMatchCreationActions
        @tournament.reset_and_fill_bout_board
        @tournament.curently_generating_matches = nil
        @tournament.save!
        Tournament.broadcast_up_matches_board(@tournament.id)
    end

    def move_finals_rows_to_last_round(match_rows)
      finals_round = match_rows.map { |row| row[:round] }.compact.max
      return unless finals_round

      match_rows.each do |row|
        row[:round] = finals_round if ["1/2", "3/4", "5/6", "7/8"].include?(row[:bracket_position])
      end
    end

    def assign_bouts_in_memory(match_rows, weights)
      bout_counts = Hash.new(0)
      weight_max_by_id = weights.each_with_object({}) { |w, memo| memo[w.id] = w.max }

      match_rows
        .sort_by { |row| [row[:round].to_i, weight_max_by_id[row[:weight_id]].to_f, row[:weight_id].to_i, row[:bracket_position_number].to_i] }
        .each do |row|
          round = row[:round].to_i
          row[:bout_number] = round * 1000 + bout_counts[round]
          bout_counts[round] += 1
        end
    end

    def assign_loser_names_in_memory(generation_context, match_rows)
      if @tournament.tournament_type == "Pool to bracket"
        service = PoolToBracketGenerateLoserNames.new(@tournament)
        generation_context[:weights].each { |weight| service.assign_loser_names_in_memory(weight, match_rows) }
      elsif @tournament.tournament_type.include?("Modified 16 Man Double Elimination")
        service = ModifiedSixteenManGenerateLoserNames.new(@tournament)
        generation_context[:weights].each { |weight| service.assign_loser_names_in_memory(weight, match_rows) }
      elsif @tournament.tournament_type.include?("Regular Double Elimination")
        service = DoubleEliminationGenerateLoserNames.new(@tournament)
        generation_context[:weights].each { |weight| service.assign_loser_names_in_memory(weight, match_rows) }
      end
    end

    def assign_bye_outcomes_in_memory(generation_context, match_rows)
      if @tournament.tournament_type.include?("Modified 16 Man Double Elimination")
        service = ModifiedSixteenManGenerateLoserNames.new(@tournament)
        generation_context[:weights].each { |weight| service.assign_bye_outcomes_in_memory(weight, match_rows) }
      elsif @tournament.tournament_type.include?("Regular Double Elimination")
        service = DoubleEliminationGenerateLoserNames.new(@tournament)
        generation_context[:weights].each { |weight| service.assign_bye_outcomes_in_memory(weight, match_rows) }
      end
    end

    def advance_bye_matches_after_insert
      Match.where(tournament_id: @tournament.id, finished: 1, win_type: "BYE")
           .where.not(winner_id: nil)
           .find_each(&:advance_wrestlers)
    end

    def assignBouts
      bout_counts = Hash.new(0)
      timestamp = Time.current
      ordered_matches = Match.joins(:weight)
                             .where(tournament_id: @tournament.id)
                             .order("matches.round ASC, weights.max ASC, matches.id ASC")
                             .pluck("matches.id", "matches.round")

      updates = []
      ordered_matches.each do |match_id, round|
        updates << {
          id: match_id,
          bout_number: round * 1000 + bout_counts[round],
          updated_at: timestamp
        }
        bout_counts[round] += 1
      end

      Match.upsert_all(updates) if updates.any?
    end

    def moveFinalsMatchesToLastRound
      finalsRound = @tournament.reload.total_rounds
      @tournament.matches
                 .where(bracket_position: ["1/2", "3/4", "5/6", "7/8"])
                 .update_all(round: finalsRound, updated_at: Time.current)
    end

    def unAssignMats
      @tournament.matches.update_all(mat_id: nil, updated_at: Time.current)
    end

    def unAssignBouts
      @tournament.matches.update_all(bout_number: nil, updated_at: Time.current)
    end
end
