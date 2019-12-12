require 'test_helper'

class PoolToBracketAdvancementTest < ActionDispatch::IntegrationTest

  def setup
    @tournament = create_pool_tournament_single_weight(10)
    @weight = Weight.where("tournament_id = ? and max = 106", @tournament.id).first
  end

  def end_all_pool_matches
    matches = Match.where("weight_id = ? and bracket_position = 'Pool'",@weight.id)
    matches.each do |match|
      if match.wrestler1.bracket_line < match.wrestler2.bracket_line
        match.winner_id = match.w1
      else
        match.winner_id = match.w2
      end
      match.finished = 1
      match.score = "2-1"
      match.save
    end
  end

  test "Pool winners are wrestling for first and pool losers are wrestling for third in two pools to finals pool bracket" do
  	end_all_pool_matches
    pool_winner_1 = Wrestler.where("weight_id = ? and pool = 1 and pool_placement = 1",@weight.id).first
    pool_runnerup_1 = Wrestler.where("weight_id = ? and pool = 1 and pool_placement = 2",@weight.id).first
    pool_winner_2 = Wrestler.where("weight_id = ? and pool = 2 and pool_placement = 1",@weight.id).first
    pool_runnerup_2 = Wrestler.where("weight_id = ? and pool = 2 and pool_placement = 2",@weight.id).first
    match_1_2 = Match.where("weight_id = ? and bracket_position = '1/2'", @weight.id).first
    match_3_4 = Match.where("weight_id = ? and bracket_position = '3/4'", @weight.id).first
    assert match_1_2.wrestler_in_match(pool_winner_1) == true
    assert match_1_2.wrestler_in_match(pool_winner_2) == true
    assert match_3_4.wrestler_in_match(pool_runnerup_1) == true
    assert match_3_4.wrestler_in_match(pool_runnerup_2) == true
  end
end