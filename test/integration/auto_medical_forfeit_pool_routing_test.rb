# frozen_string_literal: true

require 'test_helper'

class AutoMedicalForfeitPoolRoutingTest < ActionDispatch::IntegrationTest
  test 'a pool match does not overwrite semifinal routes after a medical forfeit' do
    create_a_tournament_with_single_weight('Pool to bracket', 8)
    @weight.wrestlers.each_with_index { |wrestler, index| wrestler.update!(original_seed: index + 1) }
    generate_tournament_matches(@tournament)
    wrestler = get_wrestler_by_name('Test1')
    wrestler.pool_matches.each { |match| end_match(match, wrestler.name) }
    perform_enqueued_jobs { wrestler.update!(auto_medical_forfeit: true) }

    while (match = @tournament.matches.reload.sort_by(&:round).find { |bout| bout.finished != 1 && bout.bracket_position == 'Pool' })
      if %w[Test6 Test7].include?(match.wrestler1.name)
        end_match_with_pin(match, match.wrestler1.name)
      else
        end_match(match, match.wrestler1.name)
      end
    end

    semifinal = @tournament.matches.find_by!(bracket_position: 'Semis', bracket_position_number: 1)
    assert_equal wrestler.id, semifinal.w1
    assert_equal get_wrestler_by_name('Test7').id, semifinal.winner_id
    assert_equal 'Medical Forfeit', semifinal.win_type
    other_semifinal = @tournament.matches.find_by!(bracket_position: 'Semis', bracket_position_number: 2)
    end_match(other_semifinal, other_semifinal.wrestler1.name)

    final = @tournament.matches.find_by!(bracket_position: '1/2')
    third_place = @tournament.matches.find_by!(bracket_position: '3/4')
    assert_equal [semifinal.winner_id, other_semifinal.w1], [final.w1, final.w2]
    assert_equal [wrestler.id, other_semifinal.w2], [third_place.w1, third_place.w2]
    assert_equal 1, third_place.finished
    assert_equal other_semifinal.w2, third_place.winner_id
    assert_equal 'Medical Forfeit', third_place.win_type
    assert_predicate third_place, :valid?
  end
end
