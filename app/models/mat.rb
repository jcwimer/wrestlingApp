# frozen_string_literal: true

class Mat < ApplicationRecord
  include ActionView::RecordIdentifier

  belongs_to :tournament
  has_many :matches, dependent: :nullify
  has_many :mat_assignment_rules, dependent: :destroy

  validates :name, presence: true

  QUEUE_SLOTS = %w[queue1 queue2 queue3 queue4].freeze
  SCOREBOARD_SELECTION_CACHE_TTL = 1.hour
  LAST_MATCH_RESULT_CACHE_TTL = 1.hour

  after_save :clear_queue_matches_cache
  after_commit :broadcast_up_matches_board, on: :update, if: :up_matches_queue_changed?
  after_commit :touch_assigned_match_wrestlers_for_cached_views, on: :update, if: :saved_change_to_name?

  def assign_next_match
    MatQueueOperation.new(tournament).advance(self).tap { reload }
  end

  def advance_queue!(finished_match = nil)
    MatQueueOperation.new(tournament).advance(self, finished_match).tap { reload }
  end

  def next_eligible_match
    filtered_matches = self.class.assignable_matches_for(tournament_id)

    mat_assignment_rules.each do |rule|
      filtered_matches = filtered_matches.where(weight_id: rule.weight_classes) if rule.weight_classes.any?
      filtered_matches = filtered_matches.where(bracket_position: rule.bracket_positions) if rule.bracket_positions.any?
      filtered_matches = filtered_matches.where(round: rule.rounds) if rule.rounds.any?
    end

    filtered_matches.first
  end

  def self.assignable_matches_for(tournament_id)
    Match.where(tournament_id: tournament_id)
         .where(finished: [nil, 0])  # finished is nil or 0
         .where(mat_id: nil)         # mat_id is nil
         .where.not(bout_number: nil) # bout_number is not nil
         .order(:bout_number)
         .where('loser1_name != ? OR loser1_name IS NULL', 'BYE')
         .where('loser2_name != ? OR loser2_name IS NULL', 'BYE')
         .where.not(w1: nil)
         .where.not(w2: nil)
  end

  def accepts_match?(match)
    mat_assignment_rules.all? do |rule|
      (rule.weight_classes.empty? || rule.weight_classes.include?(match.weight_id)) &&
        (rule.bracket_positions.empty? || rule.bracket_positions.include?(match.bracket_position)) &&
        (rule.rounds.empty? || rule.rounds.include?(match.round))
    end
  end

  def broadcast_queue_state
    clear_queue_matches_cache
    broadcast_current_match
  end

  def queue_match_ids
    QUEUE_SLOTS.map { |slot| public_send(slot) }
  end

  # used to prevent N+1 query on each mat
  def queue_matches
    slot_ids = queue_match_ids
    if @queue_matches.nil? || @queue_match_slot_ids != slot_ids
      ids = slot_ids.compact
      @queue_matches = if ids.empty?
                         [nil, nil, nil, nil]
                       else
                         matches_by_id = Match.where(id: ids)
                                              .includes({ wrestler1: :school }, { wrestler2: :school }, { weight: :matches })
                                              .index_by(&:id)
                         slot_ids.map { |match_id| match_id ? matches_by_id[match_id] : nil }
                       end
      @queue_match_slot_ids = slot_ids
    end
    @queue_matches
  end

  def preload_queue_matches(matches_by_id)
    slot_ids = queue_match_ids
    @queue_matches = slot_ids.map { |match_id| matches_by_id[match_id] }
    @queue_match_slot_ids = slot_ids
  end

  def queue1_match
    queue_match_at(1)
  end

  def queue2_match
    queue_match_at(2)
  end

  def queue3_match
    queue_match_at(3)
  end

  def queue4_match
    queue_match_at(4)
  end

  def queue_position_for_match(match)
    return nil unless match
    return 1 if queue1 == match.id
    return 2 if queue2 == match.id
    return 3 if queue3 == match.id
    return 4 if queue4 == match.id

    nil
  end

  def remove_match_from_queue_and_collapse!(match_id)
    MatQueueOperation.new(tournament).remove(match_id).tap { reload }
  end

  def assign_match_to_queue!(match, position)
    MatQueueOperation.new(tournament).assign(match, self, position).tap { reload }
  end

  def clear_queue!
    MatQueueOperation.new(tournament).clear(self).tap { reload }
  end

  def unfinished_matches
    matches.reject { |m| m.finished == 1 }.sort_by(&:bout_number)
  end

  def scoreboard_payload(selection: :read, last_match_result: :read)
    selected_match = selected_scoreboard_match(selection:)
    {
      mat_id: id,
      queue1_bout_number: queue1_match&.bout_number,
      queue1_match_id: queue1_match&.id,
      selected_bout_number: selected_match&.bout_number,
      selected_match_id: selected_match&.id,
      last_match_result: last_match_result_text(value: last_match_result)
    }
  end

  def update_scoreboard_state(match: nil, update_selection: false, last_match_result: nil, update_result: false) # rubocop:disable Naming/PredicateMethod
    current_selection = Rails.cache.read(scoreboard_selection_cache_key)
    current_match_id = current_selection && (current_selection[:match_id] || current_selection['match_id'])
    requested_match_id = match&.id
    selection_changed = update_selection && current_match_id != requested_match_id
    result_changed = update_result && last_match_result_text != last_match_result.presence
    return false unless selection_changed || result_changed

    if selection_changed
      if match
        Rails.cache.write(scoreboard_selection_cache_key, { match_id: match.id, bout_number: match.bout_number },
                          expires_in: SCOREBOARD_SELECTION_CACHE_TTL)
      else
        Rails.cache.delete(scoreboard_selection_cache_key)
      end
    end

    if result_changed
      if last_match_result.present?
        Rails.cache.write(last_match_result_cache_key, last_match_result,
                          expires_in: LAST_MATCH_RESULT_CACHE_TTL)
      else
        Rails.cache.delete(last_match_result_cache_key)
      end
    end

    broadcast_scoreboard_state
    true
  end
  alias update_scoreboard_state! update_scoreboard_state

  def set_selected_scoreboard_match!(match)
    update_scoreboard_state(match: match, update_selection: true)
  end

  def selected_scoreboard_match(selection: :read)
    selection = Rails.cache.read(scoreboard_selection_cache_key) if selection == :read
    return nil unless selection

    match_id = selection[:match_id] || selection['match_id']
    selected_match = queue_matches.compact.find { |match| match.id == match_id }
    return selected_match if selected_match

    Rails.cache.delete(scoreboard_selection_cache_key)
    nil
  end

  def set_last_match_result!(text)
    update_scoreboard_state(last_match_result: text, update_result: true)
  end

  def last_match_result_text(value: :read)
    value == :read ? Rails.cache.read(last_match_result_cache_key) : value
  end

  def broadcast_legacy_mat_view
    Turbo::StreamsChannel.broadcast_update_to(
      self,
      target: dom_id(self, :current_match),
      partial: 'mats/current_match',
      locals: { mat: self, match: queue1_match, next_match: queue2_match, show_next_bout_button: true }
    )
  end

  def broadcast_scoreboard_state(selection: :read, last_match_result: :read)
    MatScoreboardChannel.broadcast_to(self, scoreboard_payload(selection:, last_match_result:))
  end

  def broadcast_current_match
    broadcast_legacy_mat_view
    broadcast_scoreboard_state
  end

  private

  def clear_queue_matches_cache
    @queue_matches = nil
    @queue_match_slot_ids = nil
  end

  def touch_assigned_match_wrestlers_for_cached_views
    wrestler_ids = matches.where(finished: [nil, 0]).pluck(:w1, :w2).flatten.compact.uniq
    TournamentCacheInvalidator.wrestler_listings(wrestler_ids)
  end

  def queue_match_at(position)
    queue_matches[position - 1]
  end

  def scoreboard_selection_cache_key
    "tournament:#{tournament_id}:mat:#{id}:scoreboard_selection"
  end

  def last_match_result_cache_key
    "tournament:#{tournament_id}:mat:#{id}:last_match_result"
  end

  def broadcast_up_matches_board
    Tournament.broadcast_up_matches_board(tournament_id)
  end

  def up_matches_queue_changed?
    saved_change_to_queue1? || saved_change_to_queue2? || saved_change_to_queue3? || saved_change_to_queue4?
  end

  public :scoreboard_selection_cache_key, :last_match_result_cache_key
end
