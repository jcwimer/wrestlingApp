require 'test_helper'

class SwapWrestlersTest < ActionDispatch::IntegrationTest
  def setup
    create_pool_tournament_single_weight(8)
  end
  
  test "Wrestlers from different pools are swapped matches correctly" do
    wrestler1 = get_wrestler_by_name("Test1")
    wrestler2 = get_wrestler_by_name("Test2")
    wrestler3 = get_wrestler_by_name("Test3")
    wrestler4 = get_wrestler_by_name("Test4")

    #Set original bracket lines
    test_line_wrestler1 = wrestler1.bracket_line
    test_line_wrestler2 = wrestler2.bracket_line
    
    SwapWrestlers.new.swap_wrestlers_bracket_lines(wrestler1.id,wrestler2.id)

    #Variable needs refreshed otherwise asserts fail
    wrestler1 = get_wrestler_by_name("Test1")
    wrestler2 = get_wrestler_by_name("Test2")
    
    assert_not_empty wrestler1.match_against(wrestler3)
    assert_equal 2, wrestler1.pool
    assert_equal test_line_wrestler2, wrestler1.bracket_line

    assert_not_empty wrestler2.match_against(wrestler4)
    assert_equal 1, wrestler2.pool
    assert_equal test_line_wrestler1, wrestler2.bracket_line
  end
end
