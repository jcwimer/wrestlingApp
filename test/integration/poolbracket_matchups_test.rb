require 'test_helper'

class PoolbracketMatchupsTest < ActionDispatch::IntegrationTest
  def setup
    @tournament = Tournament.find(1)
    @genMatchups = @tournament.generateMatchups
  end
  
  test "the truth" do
    assert true
  end
  
  test "found tournament" do
    refute_nil @tournament
  end
  
  test "tests boutNumber matches round" do
    @matchup_to_test = @genMatchups.select{|m| m.boutNumber == 4000}.first
    assert_equal 4, @matchup_to_test.round
  end
  
  test "tests boutNumbers are generated with smallest weight first regardless of id" do
    @weight = @tournament.weights.map.sort_by{|x|[x.max]}.first
    @matchup = @genMatchups.select{|m| m.boutNumber == 1000}.first
    assert_equal @weight.max, @matchup.weight_max
  end
  
  test "tests number of matches in 5 man one pool" do
    @six_matches = @genMatchups.select{|m| m.weight_max == 106}
    assert_equal 10, @six_matches.length
  end
  
  test "tests number of matches in 11 man pool bracket" do
    @twentysix_matches = @genMatchups.select{|m| m.weight_max == 126}
    assert_equal 22, @twentysix_matches.length
  end
  
  test "tests number of matches in 9 man pool bracket" do
    @twentysix_matches = @genMatchups.select{|m| m.weight_max == 113}
    assert_equal 18, @twentysix_matches.length
  end
  
  test "tests number of matches in 7 man pool bracket" do
    @twentysix_matches = @genMatchups.select{|m| m.weight_max == 120}
    assert_equal 13, @twentysix_matches.length
  end
  
  test "tests number of matches in 16 man pool bracket" do
    @twentysix_matches = @genMatchups.select{|m| m.weight_max == 132}
    assert_equal 32, @twentysix_matches.length
  end
end
