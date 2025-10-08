class WrestlingdevImporter
  ##### Note, the json contains id's for each row in the tables as well as its associations
  ##### this ignores those ids and uses this tournament id and then looks up associations based on name
  ##### and this tournament id
  attr_accessor :import_data
  
  # Support both parameter styles for backward compatibility
  # Old: initialize(tournament, backup)
  # New: initialize(tournament) with import_data setter
  def initialize(tournament, backup = nil)
    @tournament = tournament
    
    # Handle the old style where backup was passed directly
    if backup.present?
      @import_data = JSON.parse(Base64.decode64(backup.backup_data)) rescue nil
    end
  end

  def import
    # Use perform_later which will execute based on centralized adapter config
    WrestlingdevImportJob.perform_later(@tournament, @import_data)
  end

  def import_raw
    @tournament.curently_generating_matches = 1
    @tournament.save
    destroy_all
    parse_data
    @tournament.curently_generating_matches = nil
    @tournament.save
  end

  def destroy_all
    # These depend directly on @tournament and will cascade deletes
    # due to `dependent: :destroy` in the Tournament model
    @tournament.schools.destroy_all # Cascades to Wrestlers, Teampointadjusts, SchoolDelegates
    @tournament.weights.destroy_all # Cascades to Wrestlers, Matches
    @tournament.mats.destroy_all    # Cascades to Matches, MatAssignmentRules
    # Explicitly destroy matches again just in case some aren't linked via mats/weights? Unlikely but safe.
    # Also handles matches linked directly to tournament if that's possible.
    @tournament.matches.destroy_all
    @tournament.mat_assignment_rules.destroy_all # Explicitly destroy rules (might be redundant if Mat cascades)
    @tournament.delegates.destroy_all
    @tournament.tournament_backups.destroy_all
    @tournament.tournament_job_statuses.destroy_all
    # Note: Teampointadjusts are deleted via School/Wrestler cascade
  end

  def parse_data
    parse_tournament(@import_data["tournament"]["attributes"])
    parse_schools(@import_data["tournament"]["schools"])
    parse_weights(@import_data["tournament"]["weights"])
    parse_mats(@import_data["tournament"]["mats"])
    parse_wrestlers(@import_data["tournament"]["wrestlers"])
    parse_matches(@import_data["tournament"]["matches"])
    parse_mat_assignment_rules(@import_data["tournament"]["mat_assignment_rules"])
  end

  def parse_tournament(attributes)
    attributes.except!("id")
    @tournament.update(attributes)
  end

  def parse_schools(schools)
    schools.each do |school_attributes|
      school_attributes.except!("id")
      School.create(school_attributes.merge(tournament_id: @tournament.id))
    end
  end

  def parse_weights(weights)
    weights.each do |weight_attributes|
      weight_attributes.except!("id")
      Weight.create(weight_attributes.merge(tournament_id: @tournament.id))
    end
  end

  def parse_mats(mats)
    mats.each do |mat_attributes|
      mat_attributes.except!("id")
      Mat.create(mat_attributes.merge(tournament_id: @tournament.id))
    end
  end

  def parse_mat_assignment_rules(mat_assignment_rules)
    mat_assignment_rules.each do |rule_attributes|
      mat_name = rule_attributes.dig("mat", "name")
      mat = Mat.find_by(name: mat_name, tournament_id: @tournament.id)
  
      # Prefer the new "weight_class_maxes" key emitted by backups (human-readable
      # max values). If not present, fall back to the legacy "weight_classes"
      # value which may be a comma-separated string or an array of IDs.
      if rule_attributes.key?("weight_class_maxes") && rule_attributes["weight_class_maxes"].respond_to?(:map)
        new_weight_classes = rule_attributes["weight_class_maxes"].map do |max_value|
          Weight.find_by(max: max_value, tournament_id: @tournament.id)&.id
        end.compact
      elsif rule_attributes["weight_classes"].is_a?(Array)
        # Already an array of IDs
        new_weight_classes = rule_attributes["weight_classes"].map(&:to_i)
      elsif rule_attributes["weight_classes"].is_a?(String)
        # Comma-separated IDs stored in the DB column; split into integers.
        new_weight_classes = rule_attributes["weight_classes"].to_s.split(",").map(&:strip).reject(&:empty?).map(&:to_i)
      else
        new_weight_classes = []
      end
  
      # Extract bracket_positions and rounds (leave as-is; model will coerce if needed)
      bracket_positions = rule_attributes["bracket_positions"]
      rounds = rule_attributes["rounds"]
  
      # Remove any keys we don't want to mass-assign (including both old/new weight keys)
      rule_attributes.except!("id", "mat", "tournament_id", "weight_classes", "weight_class_maxes")
      
      MatAssignmentRule.create(
        rule_attributes.merge(
          tournament_id: @tournament.id,
          mat_id: mat&.id,
          weight_classes: new_weight_classes,
          bracket_positions: bracket_positions,
          rounds: rounds
        )
      )
    end
  end

  def parse_wrestlers(wrestlers)
    wrestlers.each do |wrestler_attributes|
      school = School.find_by(name: wrestler_attributes["school"]["name"], tournament_id: @tournament.id)
      weight = Weight.find_by(max: wrestler_attributes["weight"]["max"], tournament_id: @tournament.id)
      wrestler_attributes.except!("id", "school", "weight")
      Wrestler.create(wrestler_attributes.merge(
        school_id: school&.id,
        weight_id: weight&.id
      ))
    end
  end

  def parse_matches(matches)
    matches.each do |match_attributes|
      next unless match_attributes # Skip if match_attributes is nil

      weight = Weight.find_by(max: match_attributes.dig("weight", "max"), tournament_id: @tournament.id)
      mat = Mat.find_by(name: match_attributes.dig("mat", "name"), tournament_id: @tournament.id)

      w1 = Wrestler.find_by(name: match_attributes["w1_name"], weight_id: weight&.id) if match_attributes["w1_name"]
      w2 = Wrestler.find_by(name: match_attributes["w2_name"], weight_id: weight&.id) if match_attributes["w2_name"]
      winner = Wrestler.find_by(name: match_attributes["winner_name"], weight_id: weight&.id) if match_attributes["winner_name"]

      match_attributes.except!("id", "weight", "mat", "w1_name", "w2_name", "winner_name", "tournament_id")

      Match.create(match_attributes.merge(
        tournament_id: @tournament.id,
        weight_id: weight&.id,
        mat_id: mat&.id,
        w1: w1&.id,
        w2: w2&.id,
        winner_id: winner&.id
      ))
    end
  end
end
