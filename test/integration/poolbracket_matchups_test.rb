require 'test_helper'

class PoolbracketMatchupsTest < ActionDispatch::IntegrationTest
  def setup
    @tournament = Tournament.find(1)
    @genMatchups = @tournament.upcomingMatches
  end

  def createTournament(numberOfWrestlers)
    @id = 6000 + numberOfWrestlers
    tournament = create_tournament
    create_school
    create_weight
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
    tournament.upcomingMatches
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

  test "tests bout_number matches round" do
    @matchup_to_test = @genMatchups.select{|m| m.bout_number == 4000}.first
    assert_equal 4, @matchup_to_test.round
  end

  test "tests bout_numbers are generated with smallest weight first regardless of id" do
    @weight = @tournament.weights.map.sort_by{|x|[x.max]}.first
    @matchup = @genMatchups.select{|m| m.bout_number == 1000}.first
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


  test "test if a wrestler can exceed five matches" do
    @count = 5
    until @count > 16 do
      @tournament2 = createTournament(@count)
      checkForByeInPool(@tournament2)
      @count = @count + 1
    end
  end

  #todo test crazy movements through each bracket?
end
