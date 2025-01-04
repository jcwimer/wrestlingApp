class TournamentBackupService
  def initialize(tournament, reason)
    @tournament = tournament
    @reason = reason
  end

  def create_backup
    if Rails.env.production?
      self.delay(:job_owner_id => @tournament.id, :job_owner_type => "Create a backup").create_backup_raw
    else
      self.create_backup_raw
    end  
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
            weight_classes: rule.weight_classes.map do |weight_id|
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
            w1_name: Wrestler.find_by(id: match.w1)&.name,
            w2_name: Wrestler.find_by(id: match.w2)&.name,
            winner_name: Wrestler.find_by(id: match.winner_id)&.name,
            weight: Weight.find_by(id: match.weight_id)&.attributes,
            mat: Mat.find_by(id: match.mat_id)&.attributes
          )
        end
      }
    }
    # puts "Generated JSON for backup: #{data[:tournament][:mats]}"
    data
  end
end
