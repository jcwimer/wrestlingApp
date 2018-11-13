require 'test_helper'

class SwapWrestlersTest < ActionDispatch::IntegrationTest
  def setup
    @tournament = tournaments(:swap_wrestlers_tournament)
    GenerateTournamentMatches.new(@tournament).generate
  end
  
  test "Wrestlers from different pools are swapped matches correctly" do
    wrestler1 = wrestlers(:swap_wrestlers_wrestler_1)
    wrestler2 = wrestlers(:swap_wrestlers_wrestler_2)
    wrestler3 = wrestlers(:swap_wrestlers_wrestler_3)
    wrestler4 = wrestlers(:swap_wrestlers_wrestler_4)
    SwapWrestlers.new.swap_wrestlers_bracket_lines(wrestler1.id,wrestler2.id)

    #Variable needs refreshed otherwise asserts fail
    wrestler1 = Wrestler.find(54)
    wrestler2 = Wrestler.find(55)
    
    assert_not_empty wrestler1.match_against(wrestler3)
    assert_equal 2, wrestler1.pool
    assert_equal 2, wrestler1.bracket_line

    assert_not_empty wrestler2.match_against(wrestler4)
    assert_equal 1, wrestler2.pool
    assert_equal 1, wrestler2.bracket_line
  end
end
