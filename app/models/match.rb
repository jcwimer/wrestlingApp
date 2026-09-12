# frozen_string_literal: true

class Match < ApplicationRecord
  include ActionView::RecordIdentifier

  RESULT_FIELDS = %w[finished winner_id win_type score overtime_type].freeze
  STAT_FIELDS = %w[w1_stat w2_stat].freeze
  STRUCTURAL_FIELDS = %w[w1 w2 weight_id tournament_id bout_number bracket_position bracket_position_number round
                         loser1_name loser2_name].freeze

  belongs_to :tournament
  belongs_to :weight
  belongs_to :mat, optional: true
  belongs_to :winner, class_name: 'Wrestler', optional: true
  belongs_to :wrestler1, class_name: 'Wrestler', foreign_key: 'w1', optional: true
  belongs_to :wrestler2, class_name: 'Wrestler', foreign_key: 'w2', optional: true
  has_many :wrestlers, through: :weight
  has_many :schools, through: :wrestlers
  validate :score_validation, :win_type_validation, :bracket_position_validation, :overtime_type_validation,
           :winner_validation

  # Callback to update finished_at when a match is finished
  before_save :update_finished_at
  after_save :remember_result_change

  # update mat show with correct match if bout board is reset
  # this is done with a turbo stream
  after_commit :broadcast_mat_assignment_change, if: :saved_change_to_mat_id?, on: %i[create update]
  after_commit :broadcast_up_matches_board, on: :update, if: :saved_change_to_mat_id?
  after_commit :invalidate_created_or_destroyed_match, on: %i[create destroy]
  after_commit :invalidate_structural_caches, on: :update, if: :structural_fields_changed?
  after_commit :handle_result_change, on: :update, if: :result_fields_changed?
  after_commit :invalidate_finished_stat_caches, on: :update, if: :finished_stats_changed?

  def finalize_once?
    with_lock do
      reload
      return false unless finished == 1 && winner_id.present? && finalized_at.nil?

      assigned_mat = mat
      update_column(:finalized_at, Time.current)
      promote_queue1_if_current_match!(assigned_mat)
      enqueue_post_finalize_jobs!
    end
    true
  end

  def result_changed_in_last_save?
    @result_fields_changed_on_save
  end

  BRACKET_POSITIONS = ['Pool', '1/2', '3/4', '5/6', '7/8', 'Quarter', 'Semis', 'Conso Semis', 'Bracket', 'Conso',
                       'Conso Quarter'].freeze
  WIN_TYPES = ['Decision', 'Major', 'Tech Fall', 'Pin', 'Forfeit', 'Injury Default', 'Default', 'DQ', 'BYE'].freeze
  OVERTIME_TYPES = ['', 'SV-1', 'TB-1', 'UTB', 'SV-2', 'TB-2', 'OT'].freeze # had to keep the blank here for validations

  def score_validation
    return unless finished == 1

    errors.add(:winner_id, 'cannot be blank') unless winner_id
    if (win_type == 'Pin') && !score.match(/^[0-5]?[0-9]:[0-5][0-9]/)
      errors.add(:score, 'needs to be in time format MM:SS when win type is Pin example: 2:23, 0:25, 10:03')
    end
    if ((win_type == 'Decision') || (win_type == 'Tech Fall') || (win_type == 'Major')) && !score.match(/^[0-9]?[0-9]-[0-9]?[0-9]/)
      errors.add(:score,
                 'needs to be in Number-Number format when win type is Decision, Tech Fall, and Major example: 10-2')
    end
    if ((win_type == 'Forfeit') || (win_type == 'Injury Default') || (win_type == 'Default') || (win_type == 'BYE') || (win_type == 'DQ')) && (score != '')
      errors.add(:score, 'needs to be blank when win type is Forfeit, Injury Default, Default, BYE, or DQ win_type')
    end
  end

  def win_type_validation
    return unless finished == 1
    return if WIN_TYPES.include? win_type

    errors.add(:win_type, "can only be one of the following #{WIN_TYPES}")
  end

  def winner_validation
    return unless winner_id
    return if [w1, w2].compact.include?(winner_id)

    errors.add(:winner_id, 'must be one of the wrestlers in the match')
  end

  def overtime_type_validation
    # overtime_type can be nil or of type OVERTIME_TYPES
    return unless !overtime_type.nil? && OVERTIME_TYPES.exclude?(overtime_type)

    errors.add(:overtime_type, "can only be one of the following #{OVERTIME_TYPES}")
  end

  def bracket_position_validation
    # Allow "Bracket Round of 16", "Bracket Round of 16.1",
    # "Conso Round of 8", "Conso Round of 8.2", etc.
    bracket_round_regex = /\A(Bracket|Conso) Round of \d+(\.\d+)?\z/

    return if BRACKET_POSITIONS.include?(bracket_position) || bracket_position.match?(bracket_round_regex)

    errors.add(:bracket_position,
               "must be one of #{BRACKET_POSITIONS} " \
               "or match the pattern 'Bracket Round of X'/'Conso Round of X'")
  end

  def consolation_match?
    bracket_position.include?('Conso') || (bracket_position == '3/4') || (bracket_position == '5/6') || (bracket_position == '7/8')
  end
  alias is_consolation_match consolation_match?

  def championship_match?
    bracket_position == 'Pool' || bracket_position == 'Quarter' || bracket_position == 'Semis' ||
      bracket_position.include?('Bracket') || bracket_position == '1/2'
  end
  alias is_championship_match championship_match?

  def calculate_school_points
    return unless w1 && w2

    wrestler1.school.calculate_score
    wrestler2.school.calculate_score
  end

  def wrestler_in_match(wrestler)
    (w1 == wrestler.id) || (w2 == wrestler.id)
  end

  def mat_assigned
    if mat
      "Mat #{mat.name}"
    else
      ''
    end
  end

  def pin_time_in_seconds
    if win_type == 'Pin'
      time = score.delete('')
      minutes_in_seconds = time.partition(':').first.to_i * 60
      sec = time.partition(':').last.to_i
      minutes_in_seconds + sec
    else
      0
    end
  end

  def advance_wrestlers?
    enqueue_post_finalize_jobs!
  end
  alias advance_wrestlers advance_wrestlers?

  def enqueue_post_finalize_jobs! # rubocop:disable Naming/PredicateMethod
    return false unless w1 || w2

    AdvanceWrestlerJob.perform_later_with_enqueue_retry([id], tournament_id)
    FillBoutBoardJob.perform_later_with_enqueue_retry(tournament_id)
    true
  end
  alias enqueue_post_finalize_jobs? enqueue_post_finalize_jobs!

  def bracket_score_string
    return '' if finished != 1

    return unless finished == 1

    overtime_type_abbreviation = ''
    overtime_type_abbreviation = " #{overtime_type}" if (overtime_type != '') && overtime_type
    case win_type
    when 'Injury Default'
      '(Inj)'
    when 'DQ'
      '(DQ)'
    when 'Forfeit'
      '(FF)'
    else
      win_type_abbreviation = win_type.chars.to_a[0..2].join.to_s
      "(#{win_type_abbreviation} #{score}#{overtime_type_abbreviation})"
    end
  end

  def w1_name
    if w1.nil?
      loser1_name
    else
      wrestler1.name
    end
  end

  def w2_name
    if w2.nil?
      loser2_name
    else
      wrestler2.name
    end
  end

  def w1_bracket_name
    first_round = first_round_for_weight
    return_string = ''
    return_string_ending = ''
    if w1 && (winner_id == w1)
      return_string = "#{return_string}<strong>"
      return_string_ending = "#{return_string_ending}</strong>"
    end
    if w1.nil?
      return_string += loser1_name.to_s
    else
      return_string = if round == first_round
                        return_string + wrestler1.long_bracket_name.to_s
                      else
                        return_string + wrestler1.short_bracket_name.to_s
                      end
    end
    return_string + return_string_ending
  end

  def w2_bracket_name
    first_round = first_round_for_weight
    return_string = ''
    return_string_ending = ''
    if w2 && (winner_id == w2)
      return_string = "#{return_string}<strong>"
      return_string_ending = "#{return_string_ending}</strong>"
    end
    if w2.nil?
      return_string += loser2_name.to_s
    else
      return_string = if round == first_round
                        return_string + wrestler2.long_bracket_name.to_s
                      else
                        return_string + wrestler2.short_bracket_name.to_s
                      end
    end
    return_string + return_string_ending
  end

  def winner_name
    return '' if finished != 1
    return w1_name if winner == wrestler1

    return unless winner == wrestler2

    w2_name
  end

  def all_results_text
    return '' if finished != 1

    winning_wrestler = winner
    if winning_wrestler == wrestler1
      losing_wrestler = wrestler2
    elsif winning_wrestler == wrestler2
      losing_wrestler = wrestler1
    else
      # Handle cases where winner is not w1 or w2 (e.g., BYE, DQ where opponent might be nil)
      # Or maybe the match hasn't been fully populated yet after a win?
      # Returning an empty string for now, but this might need review based on expected scenarios.
      return ''
    end
    # Ensure losing_wrestler is not nil before accessing its properties
    losing_wrestler_name = losing_wrestler ? losing_wrestler.name : 'Unknown'
    losing_wrestler_school = losing_wrestler ? losing_wrestler.school.name : 'Unknown'

    "#{weight.max} lbs - #{winning_wrestler.name} (#{winning_wrestler.school.name}) #{win_type} #{losing_wrestler_name} (#{losing_wrestler_school}) #{score}"
  end

  def bracket_winner_name
    # Use the winner association directly
    if winner
      "#{winner.name} (#{winner.school.abbreviation})"
    else
      ''
    end
  end

  delegate :max, to: :weight, prefix: true

  def first_round_for_weight
    return @first_round_for_weight if defined?(@first_round_for_weight)

    @first_round_for_weight =
      if association(:weight).loaded? && weight&.association(:matches)&.loaded?
        weight.matches.filter_map(&:round).min
      else
        Match.where(weight_id: weight_id).minimum(:round)
      end
  end

  def replace_loser_name_with_wrestler(wrestler, loser_name)
    if loser1_name == loser_name
      self.w1 = wrestler.id
      save
    end
    return unless loser2_name == loser_name

    self.w2 = wrestler.id
    save
  end

  def replace_loser_name_with_bye(loser_name)
    if loser1_name == loser_name
      self.loser1_name = 'BYE'
      save
    end
    return unless loser2_name == loser_name

    self.loser2_name = 'BYE'
    save
  end

  def pool_number
    return unless w1?

    wrestler1.pool
  end

  def list_w2_stats
    if w2
      "#{w2_name} (#{wrestler2.school.name}): #{w2_stat}"
    else
      ''
    end
  end

  def list_w1_stats
    if w1
      "#{w1_name} (#{wrestler1.school.name}): #{w1_stat}"
    else
      ''
    end
  end

  private

  def promote_queue1_if_current_match!(assigned_mat)
    return unless assigned_mat&.queue1 == id

    MatQueueOperation.new(tournament).promote_after_queue1_finish!(assigned_mat, self)
  end

  def update_finished_at
    # Get the changes that will be persisted
    changes = changes_to_save

    # Check if finished is changing from 0 to 1 or if it's already 1 but has no timestamp
    return unless (changes['finished'] && changes['finished'][1] == 1) || (finished == 1 && finished_at.nil?)

    self.finished_at = Time.current.utc
  end

  def handle_result_change
    winner_changed = previous_changes.key?('winner_id')
    finalized_now = finalize_once? if finished == 1 && winner_id.present?
    advancement_queued = finalized_now
    advancement_queued = reconcile_finished_result!(winner_changed: winner_changed) if finished == 1 && finalized_at.present? && !finalized_now
    invalidate_result_caches unless advancement_queued
    broadcast_result_state
  end

  def reconcile_finished_result!(winner_changed:)
    if winner_changed
      ReconcileFinishedMatchResult.new(self).call
    else
      calculate_school_points
      false
    end
  end

  def remember_result_change
    @result_fields_changed_on_save = saved_changes.keys.intersect?(RESULT_FIELDS)
  end

  def result_fields_changed?
    previous_changes.keys.intersect?(RESULT_FIELDS)
  end

  def structural_fields_changed?
    previous_changes.keys.intersect?(STRUCTURAL_FIELDS)
  end

  def finished_stats_changed?
    finished == 1 && !result_fields_changed? && previous_changes.keys.intersect?(STAT_FIELDS)
  end

  def invalidate_finished_stat_caches
    TournamentCacheInvalidator.finished_match_stats_changed([w1, w2])
  end

  def invalidate_created_or_destroyed_match
    invalidate_result_caches
  end

  def invalidate_structural_caches
    wrestler_ids = [w1, w2]
    wrestler_ids.concat(previous_changes['w1'] || [])
    wrestler_ids.concat(previous_changes['w2'] || [])
    weight_ids = [weight_id] + (previous_changes['weight_id'] || [])
    tournament_ids = [tournament_id] + (previous_changes['tournament_id'] || [])
    invalidate_cache_records(wrestler_ids, weight_ids: weight_ids, tournament_ids: tournament_ids)
  end

  def invalidate_result_caches
    invalidate_cache_records([w1, w2])
  end

  def invalidate_cache_records(wrestler_ids, weight_ids: [weight_id], tournament_ids: [tournament_id])
    TournamentCacheInvalidator.match_changed(
      wrestler_ids: wrestler_ids,
      weight_ids: weight_ids,
      tournament_ids: tournament_ids
    )
  end

  def broadcast_result_state
    MatchChannel.broadcast_to(self, {
                                w1_stat: w1_stat,
                                w2_stat: w2_stat,
                                score: score,
                                win_type: win_type,
                                winner_id: winner_id,
                                winner_name: winner&.name,
                                finished: finished,
                                scoreboard_state: Rails.cache.read("tournament:#{tournament_id}:match:#{id}:scoreboard_state")
                              })
  end

  def broadcast_mat_assignment_change
    old_mat_id, new_mat_id = saved_change_to_mat_id || previous_changes['mat_id']
    return unless old_mat_id || new_mat_id

    [old_mat_id, new_mat_id].compact.uniq.each do |mat_id|
      mat = Mat.find_by(id: mat_id)
      next unless mat

      mat.broadcast_legacy_mat_view
      mat.broadcast_scoreboard_state
    end
    TournamentCacheInvalidator.wrestler_listings([w1, w2])
  end

  def broadcast_up_matches_board
    Tournament.broadcast_up_matches_board(tournament_id)
  end
end
