class WrestlingdevImporter

  ##### Note, the json contains id's for each row in the tables as well as it's associations
  ##### this ignores those ids and uses this tournament id and then looks up associations based on name
  ##### and this tournament id
  def initialize(tournament, import_json)
    @tournament = tournament
    @import_data = JSON.parse(import_json)
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
