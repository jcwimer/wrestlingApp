require 'test_helper'

class PoolbracketMatchupsTest < ActionDispatch::IntegrationTest
  def setup
    @tournament = Tournament.find(1)
    @genMatchups = @tournament.upcomingMatches
  end
  
  def createTournament(numberOfWrestlers)
    @count = 1
    @id = 6000 + numberOfWrestlers
    @tournament3 = Tournament.new
    @tournament3.id = @id
    @tournament3.tournament_type = "Pool to bracket"
    @tournament3.name = "Something"
    @tournament3.address = "Some Place"
    @tournament3.director = "Some Guy"
    @tournament3.director_email = "test@test.com"
    @tournament3.save
    @school3 = School.new
    @school3.id = @id
    @school3.name = "Shit Show"
    @school3.tournament_id = @id
    @school3.save
    @weight3 = Weight.new
    @weight3.id = @id
    @weight3.tournament_id = @id
    @weight3.save
    until @count > numberOfWrestlers do
      @wrestler2 = Wrestler.new
      @wrestler2.name = "Guy #{@count}"
      @wrestler2.school_id = @id
      @wrestler2.weight_id = @id
      @wrestler2.original_seed = @count
      @wrestler2.season_loss = 0
      @wrestler2.season_win = 0
      @wrestler2.criteria = nil
      @wrestler2.save
      @count = @count + 1
    end
    return @tournament3
  end
  
  def checkForByeInPool(tournament)
    tournament.upcomingMatches
    @matchups = tournament.matches
    tournament.weights.each do |w|
      w.wrestlers.each do |wr|
        @round = 1
        if w.totalRounds(@matchups) > 5
          until @round > w.poolRounds(@matchups) do
            if wr.boutByRound(@round,@matchups) == "BYE"
              @message = "BYE"
            end
            @round = @round + 1
          end
          assert_equal "BYE", @message
          @message = nil
        end
      end
    end
  end
    

  test "the truth" do
    assert true
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
