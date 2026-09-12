# frozen_string_literal: true

module TournamentsHelper
  def load_bracket(weight)
    unless @bracket_data_loaded
      ActiveRecord::Associations::Preloader.new(
        records: action_name == 'all_brackets' ? @weights.to_a : [weight],
        associations: {
          matches: [{ wrestler1: :school }, { wrestler2: :school }],
          wrestlers: %i[school matches_as_w1 matches_as_w2]
        }
      ).call
      @bracket_data_loaded = true
    end
    @matches = weight.matches
    @wrestlers = weight.wrestlers
    first_round = @matches.filter_map(&:round).min
    @matches.each { |match| match.instance_variable_set(:@first_round_for_weight, first_round) }
    return unless @tournament.tournament_type == 'Pool to bracket'

    @pools = weight.pool_rounds(@matches)
    @bracket_type = weight.pool_bracket_type
  end
end
