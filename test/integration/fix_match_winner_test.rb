# frozen_string_literal: true

require 'test_helper'

class FixMatchWinner < ActionDispatch::IntegrationTest
  def setup; end

  def winner_by_name(winner_name, match)
    wrestler = @tournament.weights.first.wrestlers.find { |w| w.name == winner_name }
    match.winner_id = wrestler.id
    match.finished = 1
    match.win_type = 'Decision'
    match.score = '1-0'
    perform_enqueued_jobs { match.save }
  end

  test 'changing a finished match winner corrects both bracket destinations without refinalizing' do
    create_double_elim_tournament_single_weight(4, 'Regular Double Elimination 1-8')

    round1 = @tournament.reload.matches.select { |m| m.round == 1 }
    corrected_match = round1.find { |m| m.bracket_position_number == 1 }
    winner_by_name('Test1', corrected_match)
    finalized_at = corrected_match.reload.finalized_at
    assert_not_nil finalized_at
    winner_by_name('Test2', round1.find { |m| m.bracket_position_number == 2 })

    winner_by_name('Test4', corrected_match)
    assert_equal finalized_at, corrected_match.reload.finalized_at

    first_finals = @tournament.reload.matches.find { |m| m.bracket_position == '1/2' }
    third_finals = @tournament.reload.matches.find { |m| m.bracket_position == '3/4' }

    assert_equal 'Test4', first_finals.wrestler1.name
    assert_equal 'Test2', first_finals.wrestler2.name

    assert_equal 'Test1', third_finals.wrestler1.name
    assert_equal 'Test3', third_finals.wrestler2.name
  end

  test 'Pool to bracket pool order should run if the winner changes' do
    create_pool_tournament_single_weight(6)

    end_match(match_wrestler_vs('Test1', 'Test2'), 'Test1')
    end_match(match_wrestler_vs('Test1', 'Test3'), 'Test1')
    end_match(match_wrestler_vs('Test1', 'Test4'), 'Test1')
    end_match(match_wrestler_vs('Test1', 'Test5'), 'Test1')
    end_match(match_wrestler_vs('Test1', 'Test6'), 'Test1')

    end_match(match_wrestler_vs('Test2', 'Test3'), 'Test2')
    end_match(match_wrestler_vs('Test2', 'Test4'), 'Test2')
    end_match(match_wrestler_vs('Test2', 'Test5'), 'Test2')
    end_match(match_wrestler_vs('Test2', 'Test6'), 'Test2')

    end_match(match_wrestler_vs('Test3', 'Test4'), 'Test3')
    end_match(match_wrestler_vs('Test3', 'Test5'), 'Test3')
    end_match(match_wrestler_vs('Test3', 'Test6'), 'Test3')

    end_match(match_wrestler_vs('Test4', 'Test5'), 'Test4')
    end_match(match_wrestler_vs('Test4', 'Test6'), 'Test4')

    end_match(match_wrestler_vs('Test5', 'Test6'), 'Test5')

    assert Wrestler.find(translate_name_to_id('Test1')).pool_placement == 1
    assert Wrestler.find(translate_name_to_id('Test2')).pool_placement == 2
    assert Wrestler.find(translate_name_to_id('Test3')).pool_placement == 3
    assert Wrestler.find(translate_name_to_id('Test4')).pool_placement == 4
    assert Wrestler.find(translate_name_to_id('Test5')).pool_placement == 5
    assert Wrestler.find(translate_name_to_id('Test6')).pool_placement == 6

    end_match(match_wrestler_vs('Test1', 'Test2'), 'Test2')
    assert Wrestler.find(translate_name_to_id('Test2')).pool_placement == 1
    assert Wrestler.find(translate_name_to_id('Test1')).pool_placement == 2
    assert Wrestler.find(translate_name_to_id('Test3')).pool_placement == 3
    assert Wrestler.find(translate_name_to_id('Test4')).pool_placement == 4
    assert Wrestler.find(translate_name_to_id('Test5')).pool_placement == 5
    assert Wrestler.find(translate_name_to_id('Test6')).pool_placement == 6
  end
end
