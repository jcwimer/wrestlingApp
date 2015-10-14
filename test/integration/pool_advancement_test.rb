require 'test_helper'

class PoolAdvancementTest < ActionDispatch::IntegrationTest
  test "the truth" do
    assert true
  end

  def setup
    @tournament = Tournament.find(1)
    @tournament.generateMatchups
    nineManBracketPoolOne
  end

  def nineManBracketPoolOne
     @matches = @tournament.matches.select{|m| m.weight_id == 3 && m.bracket_position == "Pool"}
     endMatch(1002,"Guy8",@matches)
     endMatch(1003,"Guy10",@matches)
     endMatch(2002,"Guy2",@matches)
     endMatch(2003,"Guy8",@matches)
     endMatch(3003,"Guy2",@matches)
     endMatch(4002,"Guy8",@matches)
     endMatch(4003,"Guy2",@matches)
     endMatch(5002,"Guy2",@matches)
     endMatch(5003,"Guy5",@matches)
     endMatch(3002,"Guy5",@matches)
  end
  
  def endMatch(bout,winner,matches)
     @match = matches.select{|m| m.bout_number == bout}.first
     @match.finished = 1
     @match.winner_id = translateNameToId(winner)
     @match.win_type = "Decision"
     @match.save
  end
  def translateNameToId(wrestler)
    Wrestler.where("name = ?", wrestler).first.id
  end

  test "nine man outright finals advance" do
    @wrestler = Wrestler.where("name = ?", "Guy2").first
    @match = Match.where("bout_number = ?",6000).first
    assert_equal 6000, @wrestler.boutByRound(6)
  end

  test "nine man outright conso finals advance" do
    @wrestler = Wrestler.where("name = ?", "Guy8").first
    assert_equal 6001, @wrestler.boutByRound(6)
  end


end
