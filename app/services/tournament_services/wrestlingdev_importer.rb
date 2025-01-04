class WrestlingdevImporter

  ##### Note, the json contains id's for each row in the tables as well as its associations
  ##### this ignores those ids and uses this tournament id and then looks up associations based on name
  ##### and this tournament id
  def initialize(tournament, backup)
    @tournament = tournament
    @import_data = JSON.parse(Base64.decode64(backup.backup_data))
  end

  def import
    if Rails.env.production?
      self.delay(job_owner_id: @tournament.id, job_owner_type: "Importing a backup").import_raw
    else
      import_raw
    end
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
    @tournament.mat_assignment_rules.destroy_all
    @tournament.mats.destroy_all
    @tournament.matches.destroy_all
    @tournament.schools.each do |school|
      school.wrestlers.destroy_all
      school.destroy
    end
    @tournament.weights.destroy_all
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

      # Map max values of weight_classes to their new IDs
      new_weight_classes = rule_attributes["weight_classes"].map do |max_value|
        Weight.find_by(max: max_value, tournament_id: @tournament.id)&.id
      end.compact

      # Extract bracket_positions and rounds
      bracket_positions = rule_attributes["bracket_positions"]
      rounds = rule_attributes["rounds"]

      rule_attributes.except!("id", "mat", "tournament_id", "weight_classes")
      
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
