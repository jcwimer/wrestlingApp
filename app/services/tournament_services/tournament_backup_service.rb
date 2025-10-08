class TournamentBackupService
  def initialize(tournament, reason)
    @tournament = tournament
    @reason = reason
  end

  def create_backup
    # Use perform_later which will execute based on centralized adapter config
    TournamentBackupJob.perform_later(@tournament, @reason)
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
    @tournament.reload
    @tournament.schools.reload
    @tournament.weights.reload
    @tournament.mats.reload
    @tournament.mat_assignment_rules.reload
    @tournament.wrestlers.reload
    @tournament.matches.reload
    data = {
      tournament: {
        attributes: @tournament.attributes,
        schools: @tournament.schools.map(&:attributes),
        weights: @tournament.weights.map(&:attributes),
        mats: @tournament.mats.map(&:attributes),
        mat_assignment_rules: @tournament.mat_assignment_rules.map do |rule|
          rule.attributes.merge(
            mat: Mat.find_by(id: rule.mat_id)&.attributes.slice("name"),
            # Emit the human-readable max values under a distinct key to avoid
            # colliding with the raw DB-backed "weight_classes" attribute (which
            # is stored as a comma-separated string). Using a different key
            # prevents duplicate JSON keys when symbols and strings are both present.
            "weight_class_maxes" => rule.weight_classes.map do |weight_id|
              Weight.find_by(id: weight_id)&.max
            end
          )
        end,
        wrestlers: @tournament.wrestlers.map do |wrestler|
          wrestler.attributes.merge(
            school: wrestler.school&.attributes,
            weight: wrestler.weight&.attributes
          )
        end,
        matches: @tournament.matches.sort_by(&:bout_number).map do |match|
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
