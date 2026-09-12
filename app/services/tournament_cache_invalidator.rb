# frozen_string_literal: true

class TournamentCacheInvalidator
  CACHE_KEY_VERSION = 1

  class << self
    def bracket_key(weight_id, print: false)
      ['weight_bracket', CACHE_KEY_VERSION, weight_id, print]
    end

    def bracket_fragment_key(weight_id, print: false)
      fragment_key([bracket_digest_path, bracket_key(weight_id, print:)])
    end

    def team_scores_key(tournament_id)
      ['team_scores', CACHE_KEY_VERSION, tournament_id]
    end

    def team_scores_data_key(tournament_id)
      ['team_scores_data', CACHE_KEY_VERSION, tournament_id]
    end

    def school_stats_key(school_id)
      ['school_stats', CACHE_KEY_VERSION, school_id]
    end

    def school_stats_data_key(school_id)
      ['school_stats_data', CACHE_KEY_VERSION, school_id]
    end

    def school_summary_key(school_id)
      ['school_summary', CACHE_KEY_VERSION, school_id]
    end

    def school_roster_key(school_id)
      ['school_roster', CACHE_KEY_VERSION, school_id]
    end

    def weight_roster_key(weight_id)
      ['weight_roster', CACHE_KEY_VERSION, weight_id]
    end

    def wrestler_profile_key(wrestler_id)
      ['wrestler_profile', CACHE_KEY_VERSION, wrestler_id]
    end

    def match_changed(wrestler_ids:, weight_ids:, tournament_ids: nil) # rubocop:disable Lint/UnusedMethodArgument
      rows = wrestler_rows(wrestler_ids)
      brackets(weight_ids | rows.map(&:third))
      school_stats(rows.map(&:second))
      wrestler_listings(rows.map(&:first))
      wrestler_profiles(rows.map(&:first))
    end

    def tournament_changed(tournament, changes)
      brackets(Weight.where(tournament_id: tournament.id).pluck(:id)) if changes.key?('name') || changes.key?('tournament_type')
      school_summaries(School.where(tournament_id: tournament.id).pluck(:id)) if changes.key?('name')
    end

    def wrestler_changed(wrestler, changes)
      school_ids = changed_ids(changes, 'school_id', wrestler.school_id)
      weight_ids = changed_ids(changes, 'weight_id', wrestler.weight_id)
      brackets(weight_ids)
      school_stats(school_ids)
      wrestler_listings_for(school_ids:, weight_ids:)
      wrestler_profiles([wrestler.id])
    end

    def school_changed(school, changes)
      tournament_ids = changed_ids(changes, 'tournament_id', school.tournament_id)
      school_summaries([school.id]) if changes.keys.intersect?(%w[name score tournament_id])
      team_scores(tournament_ids) if changes.key?('name') || changes.key?('score')
      return unless changes.key?('name')

      wrestler_ids = Wrestler.where(school_id: school.id).pluck(:id)
      weight_ids = Wrestler.where(id: wrestler_ids).distinct.pluck(:weight_id)
      school_stats([school.id])
      wrestler_listings_for(school_ids: [school.id], weight_ids:)
      wrestler_profiles(wrestler_ids)
      brackets(weight_ids)
    end

    def weight_changed(weight, _changes)
      wrestler_rows = Wrestler.where(weight_id: weight.id).pluck(:id, :school_id)
      brackets([weight.id])
      school_stats(wrestler_rows.map(&:second))
      wrestler_listings_for(school_ids: wrestler_rows.map(&:second), weight_ids: [weight.id])
      wrestler_profiles(wrestler_rows.map(&:first))
    end

    def advancement_completed(weight_ids, wrestler_ids)
      rows = wrestler_rows(wrestler_ids)
      brackets(weight_ids)
      school_stats(rows.map(&:second))
      wrestler_listings(wrestler_ids)
      wrestler_profiles(wrestler_ids)
    end

    def team_scores_calculated(tournament_id)
      team_scores([tournament_id])
      school_summaries(School.where(tournament_id: tournament_id).pluck(:id))
    end

    def finished_match_stats_changed(wrestler_ids)
      rows = wrestler_rows(wrestler_ids)
      school_stats(rows.map(&:second))
      wrestler_profiles(rows.map(&:first))
    end

    def generation_completed(tournament_id)
      weight_ids = Weight.where(tournament_id: tournament_id).pluck(:id)
      school_ids = School.where(tournament_id: tournament_id).pluck(:id)
      wrestler_ids = Wrestler.where(weight_id: weight_ids).pluck(:id)

      brackets(weight_ids)
      school_stats(school_ids)
      wrestler_listings_for(school_ids:, weight_ids:)
      wrestler_profiles(wrestler_ids)
      team_scores([tournament_id])
      school_indexes([tournament_id])
    end

    def wrestler_listings(ids)
      rows = wrestler_rows(ids)
      wrestler_listings_for(school_ids: rows.map(&:second), weight_ids: rows.map(&:third))
    end

    def wrestler_profiles(ids)
      delete_fragments(compact_ids(ids).map { |id| wrestler_profile_key(id) })
    end

    def brackets(ids)
      keys = compact_ids(ids).flat_map do |id|
        [bracket_fragment_key(id), bracket_fragment_key(id, print: true)]
      end
      delete_keys(keys)
    end

    def school_stats(ids)
      ids = compact_ids(ids)
      delete_fragments(ids.map { |id| school_stats_key(id) })
      delete_keys(ids.map { |id| school_stats_data_key(id) })
    end

    def team_scores(ids)
      ids = compact_ids(ids)
      delete_fragments(ids.map { |id| team_scores_key(id) })
      delete_keys(ids.map { |id| team_scores_data_key(id) })
    end

    def school_indexes(ids)
      school_ids = School.where(tournament_id: compact_ids(ids)).pluck(:id)
      school_summaries(school_ids)
      delete_fragments(school_ids.map { |id| school_roster_key(id) })
    end

    def school_summaries(ids)
      delete_fragments(compact_ids(ids).map { |id| school_summary_key(id) })
    end

    private

    def wrestler_listings_for(school_ids:, weight_ids:)
      keys = compact_ids(school_ids).map { |id| school_roster_key(id) }
      keys.concat(compact_ids(weight_ids).map { |id| weight_roster_key(id) })
      delete_fragments(keys)
    end

    def wrestler_rows(ids)
      Wrestler.where(id: compact_ids(ids)).pluck(:id, :school_id, :weight_id)
    end

    def changed_ids(changes, attribute, current_id)
      compact_ids(changes[attribute] || [current_id])
    end

    def compact_ids(ids)
      Array(ids).flatten.compact.uniq
    end

    def delete_fragments(keys)
      delete_keys(keys.map { |key| fragment_key(key) })
    end

    def fragment_key(key)
      ApplicationController.new.combined_fragment_cache_key(key)
    end

    def bracket_digest_path
      @bracket_digest_path ||= begin
        view = ApplicationController.new.view_context
        template = view.lookup_context.find_template('tournaments/cached_bracket', [], true)
        view.digest_path_from_template(template)
      end
    end

    def delete_keys(keys)
      Rails.cache.delete_multi(keys.uniq) if keys.any?
    end
  end
end
