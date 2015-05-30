require 'test_helper'

class BracketingTest < ActionDispatch::IntegrationTest
  def setup
    @tournament = Tournament.first
    @tournament.createCustomWeights("hs")
    @school = School.first
    @weight = Weight.first
    @wrestlers = []
  end

  def add_wrestler
    wrestler = Wrestler.new(name: "Wrestler #{@wrestlers.size + 1}", school_id: @school.id, weight_id: @weight.id)
    wrestler.save!
    @wrestlers << wrestler
  end

  def inspect_bouts
    puts JSON.pretty_generate(@tournament.matches.as_json)
  end

  def bout_by_number(n)
    @tournament.matches.detect {|m| m.bout_number == n}
  end

  test "Create brackets but we have no wrestlers" do
    @tournament.generateMatchups
    assert_equal 0, @tournament.matches.size
  end

  test "Create brackets for a single wrestler" do
    add_wrestler
    @tournament.generateMatchups
    assert_equal 0, @tournament.matches.size
  end

  test "Create brackets for two wrestlers in the same weight class" do
    2.times { add_wrestler }
    @tournament.generateMatchups
    assert_equal 1, @tournament.matches.size
    match = @tournament.matches.first
    assert_equal 1000, match.bout_number
  end

  test "Create brackets for three wrestlers in the same weight class" do
    3.times { add_wrestler }
    @tournament.generateMatchups
    assert_equal 3, @tournament.matches.size
    bout_numbers = @tournament.matches.inject([]) { |c, m| c << m.bout_number }
    assert_equal [1000, 2000, 3000], bout_numbers
  end

  test "Create brackets for four wrestlers in the same weight class" do
    4.times { add_wrestler }
    @tournament.generateMatchups
    assert_equal 6, @tournament.matches.size
    bout_numbers = @tournament.matches.inject([]) { |c, m| c << m.bout_number }
    assert_equal [1000, 1001, 2000, 2001, 3000, 3001], bout_numbers
  end

  test "Create brackets for five wrestlers in the same weight class" do
    5.times { add_wrestler }
    @tournament.generateMatchups
    assert_equal 10, @tournament.matches.size
    bout_numbers = @tournament.matches.inject([]) { |c, m| c << m.bout_number }
    assert_equal [1000, 1001, 2000, 2001,
       3000, 3001, 4000, 4001, 5000, 5001],
      bout_numbers
  end

  test "Create brackets for six wrestlers in the same weight class" do
    6.times { add_wrestler }
    @tournament.generateMatchups
    assert_equal 1, @weight.pools
    assert_equal 15, @tournament.matches.size

    bout_numbers = @tournament.matches.collect { |m| m.bout_number }

    assert_equal [1000, 1001, 1002,
      2000, 2001, 2002,
      3000, 3001, 3002,
      4000, 4001, 4002,
      5000, 5001, 5002],
      bout_numbers
  end

  test "Create brackets for seven wrestlers in the same weight class, breaking into two pools" do
    7.times { add_wrestler }
    @tournament.generateMatchups
    assert_equal 2, @weight.pools
    assert_equal 13, @tournament.matches.size

    bout_numbers = @tournament.matches.inject([]) { |c, m| c << m.bout_number }

    assert_equal [1000, 1001, 2000, 2001, 3000, 3001,
      1002, 2002, 3002,
      4000, 4001,
      5000, 5001],
      bout_numbers
  end

  test "Create brackets for eleven wrestlers in the same weight class, breaking into four pools" do
    11.times { add_wrestler }
    @tournament.generateMatchups
    assert_equal 4, @weight.pools
    assert_equal 22, @tournament.matches.size

    bout_numbers = @tournament.matches.inject([]) { |c, m| c << m.bout_number }

    assert_equal [1000, 2000, 3000,
    1001, 2001, 3001,
    1002, 2002, 3002,
    1003,
    4000, 4001, 4002, 4003,
    5000, 5001, 5002, 5003,
    6000, 6001, 6002, 6003],
    bout_numbers

    bout_4000 = bout_by_number(4000)
    assert_equal "Quarter", bout_4000.bracket_position
    assert_equal 1, bout_4000.bracket_position_number
    assert_equal "Winner Pool 1", bout_4000.loser1_name
    assert_equal "Runner Up Pool 2", bout_4000.loser2_name
    assert_equal 4, bout_4000.round
  end

  test "all sixteen wrestlers in a weight class" do
    16.times { add_wrestler }
    @tournament.generateMatchups
    assert_equal 4, @weight.pools
    assert_equal 32, @tournament.matches.size

    bout_numbers = @tournament.matches.inject([]) { |c, m| c << m.bout_number }

    assert_equal [1000, 1001, 2000, 2001, 3000, 3001, 1002, 1003,
      2002, 2003, 3002, 3003, 1004, 1005, 2004, 2005, 3004, 3005,
      1006, 1007, 2006, 2007, 3006, 3007, 4000, 4001, 4002, 4003,
      5000, 5001, 5002, 5003],
      bout_numbers

    bout_4000 = bout_by_number(4000)

    assert_equal "Semis", bout_4000.bracket_position
    assert_equal 1, bout_4000.bracket_position_number
    assert_equal "Winner Pool 1", bout_4000.loser1_name
    assert_equal "Winner Pool 4", bout_4000.loser2_name
    assert_equal 4, bout_4000.round
  end

end
