# frozen_string_literal: true

module TournamentServices
  class WipeTournamentMatches
    def initialize(tournament)
      @tournament = tournament
    end

    def set_up_match_generation
      wipe_matches
      reset_school_scores
    end
    alias setUpMatchGeneration set_up_match_generation # rubocop:disable Naming/MethodName

    def wipe_weight_matches(weight)
      weight.matches.destroy_all
    end

    def wipe_matches
      @tournament.destroy_all_matches
    end

    def reset_school_scores
      @tournament.schools.update_all('score = 0.0')
    end
  end
end
