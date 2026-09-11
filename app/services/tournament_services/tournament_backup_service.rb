class TournamentServices::TournamentBackupService
  def initialize(tournament, reason)
    @tournament = tournament
    @reason = reason
  end

  def create_backup
    # Use perform_later which will execute based on centralized adapter config
    TournamentBackupJob.perform_later_with_enqueue_retry(@tournament, @reason)
  end

  def create_backup_raw
    # Generate the JSON directly in Ruby and encode it
    backup_data = Base64.encode64(generate_json.to_json)

    begin
      # Save the backup with encoded data
      TournamentBackup.create!(tournament: @tournament, backup_data: backup_data, backup_reason: @reason)
      Rails.logger.info("Backup created successfully for tournament ##{@tournament.id}")
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("Failed to save backup: #{e.message}")
    end
  end

  private

  def generate_json
    tournament = Tournament.includes(
      :schools,
      :mats,
      :mat_assignment_rules,
      { weights: :wrestlers },
      matches: [:wrestler1, :wrestler2, :winner, :weight, :mat]
    ).find(@tournament.id)
    weights = tournament.weights.to_a
    mats = tournament.mats.to_a
    matches = tournament.matches.to_a
    wrestlers = weights.flat_map(&:wrestlers)
    matches_by_id = matches.index_by(&:id)
    mats.each { |mat| mat.preload_queue_matches(matches_by_id) }
    mats_by_id = mats.index_by(&:id)
    weights_by_id = weights.index_by(&:id)

    data = {
      tournament: {
        attributes: tournament.attributes,
        schools: tournament.schools.map(&:attributes),
        weights: weights.map(&:attributes),
        mats: mats.map do |mat|
          mat.attributes.merge(
            "queue_bout_numbers" => mat.queue_matches.map { |match| match&.bout_number }
          )
        end,
        mat_assignment_rules: tournament.mat_assignment_rules.map do |rule|
          rule.attributes.merge(
            mat: mats_by_id[rule.mat_id]&.attributes&.slice("name"),
            # Emit the human-readable max values under a distinct key to avoid
            # colliding with the raw DB-backed "weight_classes" attribute (which
            # is stored as a comma-separated string). Using a different key
            # prevents duplicate JSON keys when symbols and strings are both present.
            "weight_class_maxes" => rule.weight_classes.map { |weight_id| weights_by_id[weight_id]&.max }
          )
        end,
        wrestlers: wrestlers.map do |wrestler|
          wrestler.attributes.merge(
            school: wrestler.school&.attributes,
            weight: wrestler.weight&.attributes
          )
        end,
        matches: matches.sort_by(&:bout_number).map do |match|
          match.attributes.merge(
            w1_name: match.wrestler1&.name,
            w2_name: match.wrestler2&.name,
            winner_name: match.winner&.name,
            weight: match.weight&.attributes,
            mat: match.mat&.attributes
          )
        end
      }
    }
    # puts "Generated JSON for backup: #{data[:tournament][:mats]}"
    data
  end
end
