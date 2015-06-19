require 'test_helper'

class PoolbracketMatchupsTest < ActionDispatch::IntegrationTest
  def setup
    @tournament = Tournament.find(1)
    @genMatchups = @tournament.generateMatchups
  end

  def createTournament(numberOfWrestlers)
    @id = 600 + numberOfWrestlers
    tournament = create_tournament
    create_school
    create_weight
    create_mat
    create_wrestlers(numberOfWrestlers)
    tournament
  end

  def create_tournament
    tournament = Tournament.new(
      id: @id,
      tournament_type: "Pool to bracket",
      name: "Something",
      address: "Some Place",
      director: "Some Guy",
      director_email: "test@test.com"
    )
    tournament.save
    tournament
  end

  def create_school
    School.new(
      id: @id,
      name: "Shit Show",
      tournament_id: @id
    ).save!
  end
  
  def create_mat
    Mat.new(
      id: @id,
      name: "Mat 1",
      tournament_id: @id
    ).save!
  end

  def create_weight
    Weight.new(
      id: @id,
      tournament_id: @id,
      max: @id
    ).save!
  end

  def create_wrestlers(numberOfWrestlers)
    (1..numberOfWrestlers).each do |count|
      Wrestler.new(
        name: "Guy #{count}",
        school_id: @id,
        weight_id: @id,
        original_seed: count,
        season_loss: 0,
        season_win: 0,
        criteria: nil
      ).save!
    end
  end

  def checkForByeInPool(tournament)
    tournament.generateMatchups
    matchups = tournament.matches
    tournament.weights.each do |w|
      w.wrestlers.each do |wr|
        round = 1
        if w.totalRounds(matchups) > 5
          until round > w.poolRounds(matchups) do
            if wr.boutByRound(round, matchups) == "BYE"
              message = "BYE"
            end
            round += 1
          end
          assert_equal "BYE", message
          message = nil
        end
      end
    end
  end

  test "found tournament" do
    refute_nil @tournament
  end

  test "tournament can be set to high school weight classes" do
    @tournament.weights.destroy_all
    @tournament.createCustomWeights("hs")
    assert_equal Weight::HS_WEIGHT_CLASSES.size, @tournament.weights.size
  end

  test "tests bout numbers correspond to round" do
    matchup_to_test = @genMatchups.select{|m| m.bout_number == 4000}.first
    assert_equal 4, matchup_to_test.round
  end

  test "tests bout_numbers are generated with smallest weight first regardless of id" do
    weight = @tournament.weights.order(:max).limit(1).first
    matchup = @tournament.matches.where(bout_number: 1000).limit(1).first
    assert_equal weight.max, matchup.weight.max
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

  test "test if a wrestler can exceed five matches" do
    (5...16).each do |count|
      tourney = createTournament(count)
      checkForByeInPool(tourney)
    end
  end

  test "test loser names for 16 man bracket 3/4th place match" do
    @matches = @tournament.matches.where(weight_id: 5)
    @semi_bouts = @matches.where(bracket_position: 'Semis')
    @third_fourth_match = @matches.where(bracket_position: '3/4').first
    assert_equal "Loser of #{@semi_bouts.first.bout_number}", @third_fourth_match.loser1_name
    assert_equal "Loser of #{@semi_bouts.second.bout_number}", @third_fourth_match.loser2_name
  end
  
  test "test loser names for 16 man bracket 7/8th place match" do
    @matches = @tournament.matches.where(weight_id: 5)
    @conso_semi_bouts = @matches.where(bracket_position: 'Conso Semis')
    @seven_eight_match = @matches.where(bracket_position: '7/8').first
    assert_equal "Loser of #{@conso_semi_bouts.first.bout_number}", @seven_eight_match.loser1_name
    assert_equal "Loser of #{@conso_semi_bouts.second.bout_number}", @seven_eight_match.loser2_name
  end
  
  test "test loser names for 16 man bracket semis" do
    @matches = @tournament.matches.where(weight_id: 5)
    @semi_bouts = @matches.where(bracket_position: 'Semis')
    assert_equal "Winner Pool 1", @semi_bouts.first.loser1_name
    assert_equal "Winner Pool 4", @semi_bouts.first.loser2_name
    assert_equal "Winner Pool 2", @semi_bouts.second.loser1_name
    assert_equal "Winner Pool 3", @semi_bouts.second.loser2_name
  end
  
  test "test loser names for 16 man bracket conso semis" do
    @matches = @tournament.matches.where(weight_id: 5)
    @conso_semi_bouts = @matches.where(bracket_position: 'Conso Semis')
    assert_equal "Runner Up Pool 1", @conso_semi_bouts.first.loser1_name
    assert_equal "Runner Up Pool 4", @conso_semi_bouts.first.loser2_name
    assert_equal "Runner Up Pool 2", @conso_semi_bouts.second.loser1_name
    assert_equal "Runner Up Pool 3", @conso_semi_bouts.second.loser2_name
  end
  
  
  test "test loser names for 11 man bracket 3/4th place match" do
    @matches = @tournament.matches.where(weight_id: 4)
    @semi_bouts = @matches.where(bracket_position: 'Semis')
    @third_fourth_match = @matches.where(bracket_position: '3/4').first
    assert_equal "Loser of #{@semi_bouts.first.bout_number}", @third_fourth_match.loser1_name
    assert_equal "Loser of #{@semi_bouts.second.bout_number}", @third_fourth_match.loser2_name
  end
  
  test "test loser names for 11 man bracket 7/8th place match" do
    @matches = @tournament.matches.where(weight_id: 4)
    @conso_semi_bouts = @matches.where(bracket_position: 'Conso Semis')
    @seven_eight_match = @matches.where(bracket_position: '7/8').first
    assert_equal "Loser of #{@conso_semi_bouts.first.bout_number}", @seven_eight_match.loser1_name
    assert_equal "Loser of #{@conso_semi_bouts.second.bout_number}", @seven_eight_match.loser2_name
  end

  test "test loser names for 11 man bracket quarters" do
    @matches = @tournament.matches.where(weight_id: 4)
    @quarters = @matches.where(bracket_position: 'Quarter')
    assert_equal "Winner Pool 1", @quarters.first.loser1_name
    assert_equal "Runner Up Pool 2", @quarters.first.loser2_name
    assert_equal "Winner Pool 4", @quarters.second.loser1_name
    assert_equal "Runner Up Pool 3", @quarters.second.loser2_name
    assert_equal "Winner Pool 2", @quarters.third.loser1_name
    assert_equal "Runner Up Pool 1", @quarters.third.loser2_name
    assert_equal "Winner Pool 3", @quarters.fourth.loser1_name
    assert_equal "Runner Up Pool 4", @quarters.fourth.loser2_name
  end
  
  test "test loser names for 11 man bracket conso semis" do
    @matches = @tournament.matches.where(weight_id: 4)
    @quarters = @matches.where(bracket_position: 'Quarter')
    @conso_semi_bouts = @matches.where(bracket_position: 'Conso Semis')
    assert_equal "Loser of #{@quarters.first.bout_number}", @conso_semi_bouts.first.loser1_name
    assert_equal "Loser of #{@quarters.second.bout_number}", @conso_semi_bouts.first.loser2_name
    assert_equal "Loser of #{@quarters.third.bout_number}", @conso_semi_bouts.second.loser1_name
    assert_equal "Loser of #{@quarters.fourth.bout_number}", @conso_semi_bouts.second.loser2_name
  end
  
 test "test loser names for 9 man bracket 3/4th place match" do
    @matches = @tournament.matches.where(weight_id: 3)
    @third_fourth_match = @matches.where(bracket_position: '3/4').first
    assert_equal "Runner Up Pool 1", @third_fourth_match.loser1_name
    assert_equal "Runner Up Pool 2", @third_fourth_match.loser2_name
  end
  
  test "test loser names for 9 man bracket 1/2 place match" do
    @matches = @tournament.matches.where(weight_id: 3)
    @final_match = @matches.where(bracket_position: '1/2').first
    assert_equal "Winner Pool 1", @final_match.loser1_name
    assert_equal "Winner Pool 2", @final_match.loser2_name
  end
  
  test "test loser names for 7 man bracket 3/4th place match" do
    @matches = @tournament.matches.where(weight_id: 2)
    @semi_bouts = @matches.where(bracket_position: 'Semis')
    @third_fourth_match = @matches.where(bracket_position: '3/4').first
    assert_equal "Loser of #{@semi_bouts.first.bout_number}", @third_fourth_match.loser1_name
    assert_equal "Loser of #{@semi_bouts.second.bout_number}", @third_fourth_match.loser2_name
  end
  
  test "test loser names for 7 man bracket semis" do
    @matches = @tournament.matches.where(weight_id: 2)
    @semi_bouts = @matches.where(bracket_position: 'Semis')
    assert_equal "Winner Pool 1", @semi_bouts.first.loser1_name
    assert_equal "Runner Up Pool 2", @semi_bouts.first.loser2_name
    assert_equal "Winner Pool 2", @semi_bouts.second.loser1_name
    assert_equal "Runner Up Pool 1", @semi_bouts.second.loser2_name
  end
end
