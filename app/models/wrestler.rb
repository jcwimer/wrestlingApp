# frozen_string_literal: true

class Wrestler < ApplicationRecord
  belongs_to :school
  belongs_to :weight
  has_one :tournament, through: :weight
  has_many :deductedPoints, class_name: 'Teampointadjust', dependent: :destroy
  ## Matches association
  # Rails associations expect only a single column so we cannot do a w1 OR w2
  # So we have to create two associations and combine them with the all_matches method
  has_many :matches_as_w1, class_name: 'Match', foreign_key: 'w1'
  has_many :matches_as_w2, class_name: 'Match', foreign_key: 'w2'
  ##
  attr_accessor :pool_advance_points, :original_id, :swap_id

  validates :name, :weight_id, :school_id, presence: true # rubocop:disable Rails/RedundantPresenceValidationOnBelongsTo
  after_commit :invalidate_cached_views, on: %i[create update]

  before_destroy unless: :destroyed_by_association do
    tournament.destroy_all_matches
  end

  before_create do
    # self.tournament.destroy_all_matches
  end

  private

  def invalidate_cached_views
    changes = previous_changes.except('updated_at')
    TournamentCacheInvalidator.wrestler_changed(self, changes) if changes.any?
  end

  public

  def last_finished_match
    all_matches.select { |m| m.finished == 1 }.max_by(&:finished_at)
  end

  def total_team_points
    WrestlerServices::CalculateWrestlerTeamScore.new(self).total_score
  end

  def team_points_earned
    WrestlerServices::CalculateWrestlerTeamScore.new(self).earned_points
  end

  def placement_points
    WrestlerServices::CalculateWrestlerTeamScore.new(self).placement_points
  end

  def total_points_deducted
    WrestlerServices::CalculateWrestlerTeamScore.new(self).deducted_points
  end

  def total_pool_points_for_pool_order
    WrestlerServices::CalculateWrestlerTeamScore.new(self).pool_points + WrestlerServices::CalculateWrestlerTeamScore.new(self).pool_bonus_points
  end

  def unfinished_pool_matches
    unfinished_matches.reject { |match| match.finished == 1 }
  end

  def next_match
    unfinished_matches.first
  end

  def next_match_position_number
    pos = last_match.bracket_position_number
    pos / 2.0
  end

  def last_match
    finished_matches.max_by(&:round)
  end

  def winner_of_last_match?
    return true if last_match && last_match.winner == self # Keep winner association change

    false
  end

  def next_match_bout_number
    if next_match
      next_match.bout_number
    else
      ''
    end
  end

  def next_match_mat_name
    if next_match
      next_match.mat_assigned
    else
      ''
    end
  end

  def unfinished_matches
    all_matches.reject { |m| m.finished == 1 }.sort_by(&:bout_number)
  end

  def result_by_bout(bout)
    bout_match_results = all_matches.select { |m| m.bout_number == bout and m.finished == 1 }
    return '' if bout_match_results.empty?

    bout_match = bout_match_results.first
    return "W #{bout_match.bracket_score_string}" if bout_match.winner == self # Keep winner association change

    "L #{bout_match.bracket_score_string}"
  end

  def result_by_id(id)
    bout_match_results = all_matches.select { |m| m.id == id and m.finished == 1 }
    return '' if bout_match_results.empty?

    bout_match = bout_match_results.first
    return "W #{bout_match.bracket_score_string}" if bout_match.winner == self # Keep winner association change

    "L #{bout_match.bracket_score_string}"
  end

  def match_against(opponent)
    all_matches.select { |m| m.w1 == opponent.id or m.w2 == opponent.id }
  end

  def wrestling_this_round?(_match_round)
    return false if all_matches.blank?

    # Original logic checked blank?, not specific round. Reverting to that.
    true
  end

  def bout_by_round(round)
    round_match = all_matches.find { |m| m.round == round }
    return 'BYE' if round_match.blank?

    round_match.bout_number
  end

  def match_id_by_round(round)
    round_match = all_matches.find { |m| m.round == round }
    return 'BYE' if round_match.blank?

    round_match.id
  end

  # Restore all_matches method
  def all_matches
    # Combine the two specific associations.
    # This returns an Array, similar to the previous select method.
    # Add .uniq for safety and sort for consistent order.
    (matches_as_w1 + matches_as_w2).uniq.sort_by(&:bout_number)
  end

  def pool_matches
    all_matches.select { |m| m.bracket_position == 'Pool' }
  end

  def a_pool_bye?
    # Revert back to using all_matches here too? Seems complex.
    # Sticking with original: uses `matches` (all weight) and `pool_matches` (derived from all_matches)
    return true if weight.pool_rounds(all_matches) > pool_matches.size

    false
  end

  def championship_advancement_wins
    matches_won.select do |m|
      (m.bracket_position == 'Quarter' or m.bracket_position == 'Semis' or m.bracket_position.include? 'Bracket') and m.win_type != 'BYE'
    end
  end

  def consolation_advancement_wins
    matches_won.select { |m| (m.bracket_position.include? 'Conso') and m.win_type != 'BYE' }
  end

  def championship_byes
    matches_won.select do |m|
      (m.bracket_position == 'Quarter' or m.bracket_position == 'Semis' or m.bracket_position.include? 'Bracket') and m.win_type == 'BYE'
    end
  end

  def consolation_byes
    matches_won.select { |m| (m.bracket_position.include? 'Conso') and m.win_type == 'BYE' }
  end

  def finished_matches
    all_matches.select { |m| m.finished == 1 }
  end

  def finished_bracket_matches
    finished_matches.reject { |m| m.bracket_position == 'Pool' }
  end

  def finished_pool_matches
    finished_matches.select { |m| m.bracket_position == 'Pool' }
  end

  def matches_won
    all_matches.select { |m| m.winner_id == id }
  end

  def pool_wins
    matches_won.select { |m| m.bracket_position == 'Pool' and m.win_type != 'BYE' }
  end

  def pin_wins
    matches_won.select do |m|
      ['Pin', 'Forfeit', 'Injury Default', 'Default', 'DQ'].include?(m.win_type)
    end
  end

  def tech_wins
    matches_won.select { |m| m.win_type == 'Tech Fall' }
  end

  def major_wins
    matches_won.select { |m| m.win_type == 'Major' }
  end

  def decision_wins
    matches_won.select { |m| m.win_type == 'Decision' }
  end

  def decision_points_scored
    points_scored = 0
    decision_wins.each do |m|
      score_of_match = m.score.delete(' ')
      score_one = score_of_match.partition('-').first.to_i
      score_two = score_of_match.partition('-').last.to_i
      if score_one > score_two
        points_scored += score_one
      elsif score_two > score_one
        points_scored += score_two
      end
    end
    points_scored
  end

  def decision_points_scored_pool
    points_scored = 0
    decision_wins.select { |m| m.bracket_position == 'Pool' }.each do |m|
      score_of_match = m.score.delete(' ')
      score_one = score_of_match.partition('-').first.to_i
      score_two = score_of_match.partition('-').last.to_i
      if score_one > score_two
        points_scored += score_one
      elsif score_two > score_one
        points_scored += score_two
      end
    end
    points_scored
  end

  def fastest_pin
    pin_wins.min_by(&:pin_time_in_seconds)
  end

  def fastest_pin_pool
    pin_wins.select { |m| m.bracket_position == 'Pool' }.min_by(&:pin_time_in_seconds)
  end

  def pin_time
    time = 0
    pin_wins.each do |m|
      time += m.pin_time_in_seconds
    end
    time
  end

  def pin_time_pool
    time = 0
    pin_wins.select { |m| m.bracket_position == 'Pool' }.each do |m|
      time += m.pin_time_in_seconds
    end
    time
  end

  def season_win_percentage
    win = season_win.to_f
    loss = season_loss.to_f
    # Revert to original logic
    if win.positive? && !loss.nil?
      match_total = win + loss
      return 0 unless match_total.positive?

      percentage_dec = win / match_total
      percentage = percentage_dec * 100
      percentage.to_i

    # Avoid division by zero if somehow win > 0 but total <= 0

    elsif season_win.nil? || season_loss.nil? || season_win.zero?
      0
    end
  end

  def long_bracket_name
    # Revert to original logic
    return_string = ''
    return_string += "[#{original_seed}] " if original_seed
    return_string += "#{name} - #{school.name}"
    return_string += " (#{season_win}-#{season_loss})" if season_win && season_loss
    return_string
  end

  def short_bracket_name
    # Revert to original logic
    "#{name} (#{school.abbreviation})"
  end

  def name_with_school
    # Revert to original logic
    "#{name} - #{school.name}"
  end
end
