# frozen_string_literal: true

require 'test_helper'

class AutoMedicalForfeitByeCascadeTest < ActionDispatch::IntegrationTest
  ['Modified 16 Man Double Elimination 1-6', 'Modified 16 Man Double Elimination 1-8'].each do |tournament_type|
    test "a medical forfeit wrestler advances when a later bye arrives in #{tournament_type}" do
      create_a_tournament_with_single_weight(tournament_type, 8)
      @weight.wrestlers.each_with_index { |wrestler, index| wrestler.update!(original_seed: index + 1) }
      flagged_wrestlers = @weight.wrestlers.order(:original_seed).first(2)
      flagged_wrestlers.each { |wrestler| wrestler.update!(auto_medical_forfeit: true) }
      flagged_wrestler_ids = flagged_wrestlers.map(&:id)
      generate_tournament_matches(@tournament)

      wrestler = flagged_wrestlers.first.reload
      consolation_bye = wrestler.all_matches.find { |match| match.bracket_position == 'Conso Quarter' }
      assert_not_nil consolation_bye
      assert_equal 'BYE', consolation_bye.loser2_name
      assert_equal 1, consolation_bye.finished
      assert_equal wrestler.id, consolation_bye.winner_id
      assert_equal 'BYE', consolation_bye.win_type

      while (match = @tournament.matches.reload.sort_by(&:round).find { |bout| bout.finished != 1 && bout.w1 && bout.w2 })
        assert_empty [match.w1, match.w2] & flagged_wrestler_ids
        end_match(match, match.wrestler1.name)
      end

      assert_empty(@tournament.matches.reload.reject { |match| match.finished == 1 })
      flagged_wrestlers.each do |flagged|
        contested_matches = flagged.reload.all_matches.select { |match| match.w1 && match.w2 }
        assert_operator contested_matches.size, :>=, 2
        contested_matches.each do |match|
          assert_equal 'Medical Forfeit', match.win_type
          opponent_id = ([match.w1, match.w2] - [flagged.id]).first
          if flagged_wrestler_ids.include?(opponent_id)
            assert_includes [match.w1, match.w2], match.winner_id
          else
            assert_equal opponent_id, match.winner_id
          end
        end
      end
    end
  end
end
