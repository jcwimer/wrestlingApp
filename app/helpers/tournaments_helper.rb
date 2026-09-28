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

  def interactive_bracket_sections(weight, matches)
    by_position = matches.group_by(&:bracket_position)
    sections = []

    sections << { key: 'pools', label: 'Pools' } if by_position['Pool']

    championship = by_position.keys.select { |position| position.start_with?('Bracket ') || %w[Quarter Semis 1/2].include?(position) }
    sections << { key: 'championship', label: 'Championship Bracket', rounds: interactive_rounds(by_position, championship) } if championship.any?

    consolation = by_position.keys.select { |position| position.start_with?('Conso ') }
    two_pool_bracket = weight.tournament.tournament_type == 'Pool to bracket' && weight.pools == 2
    consolation_final = weight.tournament.tournament_type.include?('Regular Double Elimination') || two_pool_bracket ? '3/4' : '5/6'
    consolation << consolation_final if by_position[consolation_final] && (consolation.any? || two_pool_bracket)
    sections << { key: 'consolation', label: 'Consolation Bracket', rounds: interactive_rounds(by_position, consolation) } if consolation.any?

    placements = %w[3/4 5/6 7/8].select { |position| by_position[position] && consolation.exclude?(position) }
    sections << { key: 'placement', label: 'Placement Matches', rounds: interactive_rounds(by_position, placements) } if placements.any?
    sections
  end

  def interactive_rounds(by_position, positions)
    positions.sort_by { |position| [by_position.fetch(position).map(&:round).min, position] }.map do |position|
      { label: position.delete_prefix('Bracket ').sub('Conso ', 'Consolation '),
        matches: by_position.fetch(position).sort_by(&:bracket_position_number) }
    end
  end
end
