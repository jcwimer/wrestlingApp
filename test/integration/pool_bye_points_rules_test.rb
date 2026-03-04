require 'test_helper'

class PoolByePointsRulesTest < ActionDispatch::IntegrationTest
  def finish_pool_match_for_wrestler(wrestler)
    match = wrestler.pool_matches.select { |m| m.finished != 1 }.first
    return if match.nil?

    match.w1 = wrestler.id
    match.winner_id = wrestler.id
    match.finished = 1
    match.win_type = "Decision"
    match.score = "1-0"
    match.save!
  end

  test "single pool wrestlers do not get pool bye points" do
    create_pool_tournament_single_weight(6)
    wrestler = @tournament.weights.first.wrestlers.first
    finish_pool_match_for_wrestler(wrestler)

    wrestler_points_calc = CalculateWrestlerTeamScore.new(wrestler)
    assert_equal 0, wrestler_points_calc.byePoints
  end

  test "pool bye points are not awarded when pools are even" do
    create_pool_tournament_single_weight(8)
    wrestler = @tournament.weights.first.wrestlers.first
    finish_pool_match_for_wrestler(wrestler)

    wrestler_points_calc = CalculateWrestlerTeamScore.new(wrestler)
    assert_equal 0, wrestler_points_calc.byePoints
  end

  test "pool bye points are awarded once when wrestler is in a smaller pool" do
    create_pool_tournament_single_weight(9)
    weight = @tournament.weights.first
    smallest_pool = (1..weight.pools).min_by { |pool_number| weight.wrestlers_in_pool(pool_number).size }
    wrestler = weight.wrestlers_in_pool(smallest_pool).first

    finish_pool_match_for_wrestler(wrestler)
    finish_pool_match_for_wrestler(wrestler)

    wrestler_points_calc = CalculateWrestlerTeamScore.new(wrestler)
    assert_equal 2, wrestler_points_calc.byePoints
  end
end
