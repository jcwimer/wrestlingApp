# frozen_string_literal: true

module TournamentServices
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
      return if backup.blank?

      @import_data = begin
        JSON.parse(Base64.decode64(backup.backup_data))
      rescue StandardError
        nil
      end
    end

    def import
      # Use perform_later which will execute based on centralized adapter config
      WrestlingdevImportJob.perform_later_with_enqueue_retry(@tournament, @import_data)
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
      weight_ids = @tournament.weights.select(:id)
      school_ids = @tournament.schools.select(:id)
      wrestler_ids = Wrestler.where(weight_id: weight_ids).select(:id)

      Match.where(tournament_id: @tournament.id).delete_all
      Teampointadjust.where(wrestler_id: wrestler_ids).or(Teampointadjust.where(school_id: school_ids)).delete_all
      Wrestler.where(id: wrestler_ids).delete_all
      SchoolDelegate.where(school_id: school_ids).delete_all
      MatAssignmentRule.where(tournament_id: @tournament.id).delete_all
      @tournament.delegates.delete_all
      @tournament.tournament_job_statuses.delete_all
      @tournament.mats.delete_all
      @tournament.weights.delete_all
      @tournament.schools.delete_all
    end

    def parse_data
      parse_tournament(@import_data['tournament']['attributes'])
      parse_schools(@import_data['tournament']['schools'])
      parse_weights(@import_data['tournament']['weights'])
      parse_mats(@import_data['tournament']['mats'])
      parse_wrestlers(@import_data['tournament']['wrestlers'])
      parse_matches(@import_data['tournament']['matches'])
      apply_mat_queues
      parse_mat_assignment_rules(@import_data['tournament']['mat_assignment_rules'])
      TournamentCacheInvalidator.generation_completed(@tournament.id)
    end

    def parse_tournament(attributes)
      attributes.except!('id')
      @tournament.update(attributes)
    end

    def parse_schools(schools)
      schools.each do |school_attributes|
        school_attributes.except!('id')
        School.create(school_attributes.merge(tournament_id: @tournament.id))
      end
      @schools_by_name = School.where(tournament_id: @tournament.id).index_by(&:name)
    end

    def parse_weights(weights)
      rows = weights.map do |weight_attributes|
        weight_attributes.except!('id')
        weight_attributes.merge(tournament_id: @tournament.id)
      end
      Weight.insert_all!(rows) if rows.any?
      @weights_by_max = Weight.where(tournament_id: @tournament.id).index_by { |weight| weight.max.to_f }
    end

    def parse_mats(mats)
      @mat_queue_bout_numbers = {}
      rows = mats.map do |mat_attributes|
        mat_name = mat_attributes['name']
        queue_bout_numbers = mat_attributes['queue_bout_numbers']
        mat_attributes.except!('id', 'queue1', 'queue2', 'queue3', 'queue4', 'queue_bout_numbers', 'tournament_id')
        @mat_queue_bout_numbers[mat_name] = queue_bout_numbers if mat_name && queue_bout_numbers
        mat_attributes.merge(tournament_id: @tournament.id)
      end
      Mat.insert_all!(rows) if rows.any?
      @mats_by_name = Mat.where(tournament_id: @tournament.id).index_by(&:name)
    end

    def parse_mat_assignment_rules(mat_assignment_rules)
      mat_assignment_rules.each do |rule_attributes|
        mat_name = rule_attributes.dig('mat', 'name')
        mat = @mats_by_name[mat_name]

        # Prefer the new "weight_class_maxes" key emitted by backups (human-readable
        # max values). If not present, fall back to the legacy "weight_classes"
        # value which may be a comma-separated string or an array of IDs.
        new_weight_classes = if rule_attributes.key?('weight_class_maxes') && rule_attributes['weight_class_maxes'].respond_to?(:map)
                               rule_attributes['weight_class_maxes'].filter_map do |max_value|
                                 @weights_by_max[max_value.to_f]&.id
                               end
                             elsif rule_attributes['weight_classes'].is_a?(Array)
                               # Already an array of IDs
                               rule_attributes['weight_classes'].map(&:to_i)
                             elsif rule_attributes['weight_classes'].is_a?(String)
                               # Comma-separated IDs stored in the DB column; split into integers.
                               rule_attributes['weight_classes'].to_s.split(',').map(&:strip).reject(&:empty?).map(&:to_i)
                             else
                               []
                             end

        # Extract bracket_positions and rounds (leave as-is; model will coerce if needed)
        bracket_positions = rule_attributes['bracket_positions']
        rounds = rule_attributes['rounds']

        # Remove any keys we don't want to mass-assign (including both old/new weight keys)
        rule_attributes.except!('id', 'mat', 'tournament_id', 'weight_classes', 'weight_class_maxes')

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
      rows = wrestlers.map do |wrestler_attributes|
        school = @schools_by_name[wrestler_attributes['school']['name']]
        weight = @weights_by_max[wrestler_attributes['weight']['max'].to_f]
        wrestler_attributes.except!('id', 'school', 'weight')
        wrestler_attributes.merge(
          school_id: school&.id,
          weight_id: weight&.id
        )
      end
      Wrestler.insert_all!(rows) if rows.any?
      @wrestlers_by_weight_and_name = Wrestler.where(weight_id: @weights_by_max.values.map(&:id)).index_by do |wrestler|
        [wrestler.weight_id, wrestler.name]
      end
    end

    def parse_matches(matches)
      rows = matches.filter_map do |match_attributes|
        next unless match_attributes # Skip if match_attributes is nil

        weight = @weights_by_max[match_attributes.dig('weight', 'max').to_f]
        mat = @mats_by_name[match_attributes.dig('mat', 'name')]

        w1 = @wrestlers_by_weight_and_name[[weight&.id, match_attributes['w1_name']]] if match_attributes['w1_name']
        w2 = @wrestlers_by_weight_and_name[[weight&.id, match_attributes['w2_name']]] if match_attributes['w2_name']
        if match_attributes['winner_name']
          winner = @wrestlers_by_weight_and_name[[weight&.id,
                                                  match_attributes['winner_name']]]
        end

        match_attributes.except!('id', 'weight', 'mat', 'w1_name', 'w2_name', 'winner_name', 'tournament_id')

        match_attributes.merge(
          tournament_id: @tournament.id,
          weight_id: weight&.id,
          mat_id: mat&.id,
          w1: w1&.id,
          w2: w2&.id,
          winner_id: winner&.id
        )
      end
      Match.insert_all!(rows) if rows.any?
      @matches_by_bout_number = Match.where(tournament_id: @tournament.id).index_by(&:bout_number)
    end

    def apply_mat_queues
      if @mat_queue_bout_numbers.blank?
        Mat.where(tournament_id: @tournament.id).find_each do |mat|
          match_ids = mat.matches.where(finished: [nil, 0]).order(:bout_number).limit(4).pluck(:id)
          mat.update_columns(
            queue1: match_ids[0],
            queue2: match_ids[1],
            queue3: match_ids[2],
            queue4: match_ids[3]
          )
        end
        return
      end

      @mat_queue_bout_numbers.each do |mat_name, bout_numbers|
        mat = @mats_by_name[mat_name]
        next unless mat

        matches = Array(bout_numbers).map do |bout_number|
          @matches_by_bout_number[bout_number]
        end

        mat.update_columns(
          queue1: matches[0]&.id,
          queue2: matches[1]&.id,
          queue3: matches[2]&.id,
          queue4: matches[3]&.id
        )

        matches.compact.each do |match|
          match.update(mat_id: mat.id)
        end
      end

      Mat.where(tournament_id: @tournament.id)
         .where(queue1: nil, queue2: nil, queue3: nil, queue4: nil)
         .find_each do |mat|
        match_ids = mat.matches.where(finished: [nil, 0]).order(:bout_number).limit(4).pluck(:id)
        mat.update_columns(
          queue1: match_ids[0],
          queue2: match_ids[1],
          queue3: match_ids[2],
          queue4: match_ids[3]
        )
      end
    end
  end
end
