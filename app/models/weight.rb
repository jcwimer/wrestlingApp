# frozen_string_literal: true

class Weight < ApplicationRecord
  belongs_to :tournament
  has_many :wrestlers, dependent: :destroy
  has_many :matches, dependent: :destroy

  validates :max, presence: true
  before_destroy :prepare_dependents_for_destroy, prepend: true, unless: :destroyed_by_association
  after_commit :invalidate_cached_views, on: %i[create update]

  # passed via layouts/_tournament-navbar.html.erb
  # tournaments controller does a .split(',') on this string and creates an array via commas
  # tournament model runs the code via method create_pre_defined_weights
  HS_WEIGHT_CLASSES = '106,113,120,126,132,138,144,150,157,165,175,190,215,285'
  HS_GIRLS_WEIGHT_CLASSES = '100,105,110,115,120,125,130,135,140,145,155,170,190,235'
  MS_WEIGHT_CLASSES = '80,86,92,98,104,110,116,122,128,134,142,150,160,172,205,245'
  MS_GIRLS_WEIGHT_CLASSES = '72,80,86,92,98,104,110,116,122,128,134,142,155,170,190,235'

  before_save do
    # self.tournament.destroy_all_matches
  end

  def pools_with_bye
    pool = 1
    pools_with_a_bye = []
    until pool > pools
      pools_with_a_bye << pool if wrestlers_in_pool(pool).first.a_pool_bye?
      pool += 1
    end
    pools_with_a_bye
  end

  def wrestlers_in_pool(pool_number)
    wrestlers.select { |w| w.pool == pool_number }
  end

  def destroy_with_dependents!
    prepare_dependents_for_destroy
    destroy!
  end

  private

  def invalidate_cached_views
    changes = previous_changes.except('updated_at').slice('max', 'tournament_id')
    TournamentCacheInvalidator.weight_changed(self, changes) if changes.any?
  end

  def prepare_dependents_for_destroy
    return if @dependents_prepared_for_destroy

    @dependents_prepared_for_destroy = true
    tournament.destroy_all_matches
    wrestler_ids = Wrestler.where(weight_id: id).select(:id)
    Teampointadjust.where(wrestler_id: wrestler_ids).delete_all
    Wrestler.where(weight_id: id).delete_all
    wrestlers.reset
    matches.reset
  end

  public

  def one_pool_empty?
    (1..pools).each do |pool|
      return true if wrestlers_in_pool(pool).empty?
    end
    false
  end

  def all_pool_matches_finished?(pool)
    wrestlers = wrestlers_in_pool(pool)
    wrestlers.each do |w|
      return false if w.pool_matches.size != w.finished_pool_matches.size
    end
    true
  end
  alias all_pool_matches_finished all_pool_matches_finished?

  def pools
    wrestlers = self.wrestlers
    @pools = if wrestlers.size <= 6
               1
             elsif (wrestlers.size > 6) && (wrestlers.size <= 10)
               2
             elsif (wrestlers.size > 10) && (wrestlers.size <= 16)
               4
             elsif (wrestlers.size > 16) && (wrestlers.size <= 24)
               8
             end
  end

  def pool_wrestlers_sorted_by_bracket_line(pool)
    # wrestlers_in_pool(pool).sort_by{|w| [w.original_seed ? 0 : 1, w.original_seed || 0]}
    wrestlers_in_pool(pool).sort_by(&:bracket_line)
  end

  def swap_wrestlers_bracket_lines(wrestler1_id, wrestler2_id)
    WrestlerServices::SwapWrestlers.new.swap_wrestlers_bracket_lines(wrestler1_id, wrestler2_id)
  end

  def bracket_size
    wrestlers.size
  end

  def pool_bracket_type
    if wrestlers.size > 6 && wrestlers.size <= 8
      'twoPoolsToSemi'
    elsif wrestlers.size > 8 && wrestlers.size <= 10
      'twoPoolsToFinal'
    elsif [11, 12].include?(wrestlers.size)
      'fourPoolsToQuarter'
    elsif wrestlers.size > 12 && wrestlers.size <= 16
      'fourPoolsToSemi'
    elsif wrestlers.size > 16 && wrestlers.size <= 24
      'eightPoolsToQuarter'
    elsif wrestlers.size <= 6
      'onePool'
    end
  end

  def pool_full?(pool)
    current_wrestlers = wrestlers_in_pool(pool)
    max = case pool_bracket_type
          when 'twoPoolsToSemi', 'fourPoolsToSemi'
            4
          when 'twoPoolsToFinal'
            5
          when 'fourPoolsToQuarter', 'eightPoolsToQuarter'
            3
          end
    max == current_wrestlers
  end

  def pool_rounds(matches)
    matchups = matches.select { |m| m.weight_id == id }
    pool_matches = matchups.select { |m| m.bracket_position == 'Pool' }
    pool_matches.max_by(&:round).round
  end

  def total_rounds(matches)
    @matchups = matches.select { |m| m.weight_id == id }
    @last_round = matches.max_by(&:round).round
    count = 0
    @round = 1
    until @round > @last_round
      count += 1 if @matchups.select { |m| m.round == @round }
      @round += 1
    end
    count
  end

  def pool_placement_order(pool)
    # BracketAdvancement::PoolOrder.new(wrestlers_in_pool(pool)).get_pool_order
  end

  def wrestlers_without_pool_assignment
    wrestlers.select { |w| w.pool.nil? }
  end

  def calculate_bracket_size
    num_wrestlers = wrestlers.size
    return nil if num_wrestlers <= 0 # Handle invalid input

    # Find the smallest power of 2 greater than or equal to num_wrestlers
    2**Math.log2(num_wrestlers).ceil
  end

  def highest_bracket_round
    bracket_matches_sorted_by_round_descending = matches.select do |m|
      m.bracket_position.include? 'Bracket'
    end.sort_by(&:round).reverse
    return bracket_matches_sorted_by_round_descending.first.round if bracket_matches_sorted_by_round_descending.size.positive?

    nil
  end

  def lowest_bracket_round
    bracket_matches_sorted_by_round_ascending = matches.select do |m|
      m.bracket_position.include? 'Bracket'
    end.sort_by(&:round)
    return bracket_matches_sorted_by_round_ascending.first.round if bracket_matches_sorted_by_round_ascending.size.positive?

    nil
  end

  def highest_conso_round
    conso_matches_sorted_by_round_descending = matches.select do |m|
      m.bracket_position.include? 'Conso'
    end.sort_by(&:round).reverse
    return conso_matches_sorted_by_round_descending.first.round if conso_matches_sorted_by_round_descending.size.positive?

    nil
  end

  def lowest_conso_round
    conso_matches_sorted_by_round_ascending = matches.select do |m|
      m.bracket_position.include? 'Conso'
    end.sort_by(&:round)
    return conso_matches_sorted_by_round_ascending.first.round if conso_matches_sorted_by_round_ascending.size.positive?

    nil
  end
end
