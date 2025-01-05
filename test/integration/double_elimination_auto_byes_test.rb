require 'test_helper'

class DoubleEliminationAutoByes < ActionDispatch::IntegrationTest
  def setup
  end

  def winner_by_name(winner_name,match)
    wrestler = @tournament.weights.first.wrestlers.select{|w| w.name == winner_name}.first
    match.winner_id = wrestler.id
    match.finished = 1
    match.win_type = "Decision"
    match.score = "0-0"
    match.save
  end

  test "8 man double elimination bracket with only 6 guys deletes one guy and auto advances byes and matches with a bye never get assigned to a mat" do
    create_double_elim_tournament_single_weight_1_6(6)
    mat = Mat.create!(name: "Mat 1", tournament_id: @tournament.id)
    test3_wrestler = @tournament.weights.first.wrestlers.select{|w| w.name == "Test6"}.first.destroy

    GenerateTournamentMatches.new(@tournament.reload).generate
    matches = @tournament.matches.reload

    round1 = matches.select{|m| m.round == 1}
    assert round1.select{|m| m.bracket_position_number == 1}.first.wrestler1.name == "Test1"
    assert round1.select{|m| m.bracket_position_number == 1}.first.loser2_name == "BYE"
    assert round1.select{|m| m.bracket_position_number == 2}.first.wrestler1.name == "Test4"
    assert round1.select{|m| m.bracket_position_number == 2}.first.wrestler2.name == "Test5"
    assert round1.select{|m| m.bracket_position_number == 3}.first.wrestler1.name == "Test3"
    assert round1.select{|m| m.bracket_position_number == 3}.first.loser2_name == "BYE"
    assert round1.select{|m| m.bracket_position_number == 4}.first.wrestler1.name == "Test2"
    assert round1.select{|m| m.bracket_position_number == 4}.first.loser2_name == "BYE"
    winner_by_name("Test4", round1.select{|m| m.bracket_position_number == 2}.first)
    assert mat.reload.unfinished_matches.first.loser1_name != "BYE"
    assert mat.reload.unfinished_matches.first.loser2_name != "BYE"

    semis = matches.select{|m| m.bracket_position == "Semis"}.sort_by{|m| m.bracket_position_number}
    assert semis.first.reload.wrestler1.name == "Test1"
    assert semis.first.reload.wrestler2.name == "Test4"
    assert semis.second.reload.wrestler1.name == "Test3"
    assert semis.second.reload.wrestler2.name == "Test2"
    winner_by_name("Test4",semis.first)
    assert mat.reload.unfinished_matches.first.loser1_name != "BYE"
    assert mat.reload.unfinished_matches.first.loser2_name != "BYE"
    winner_by_name("Test2",semis.second)
    assert mat.reload.unfinished_matches.first.loser1_name != "BYE"
    assert mat.reload.unfinished_matches.first.loser2_name != "BYE"

    conso_quarter = matches.select{|m| m.bracket_position == "Conso Quarter"}.sort_by{|m| m.bracket_position_number}
    assert conso_quarter.first.reload.loser1_name == "BYE"
    assert conso_quarter.first.reload.wrestler2.name == "Test5"
    assert conso_quarter.second.reload.loser1_name == "BYE"
    assert conso_quarter.second.reload.loser2_name == "BYE"

    conso_semis = matches.select{|m| m.bracket_position == "Conso Semis"}.sort_by{|m| m.bracket_position_number}
    assert conso_semis.first.reload.wrestler1.name == "Test3"
    assert conso_semis.first.reload.wrestler2.name == "Test5"
    assert conso_semis.second.reload.wrestler1.name == "Test1"
    assert conso_semis.second.reload.loser2_name == "BYE"
    winner_by_name("Test5",conso_semis.first)
    assert mat.reload.unfinished_matches.first.loser1_name != "BYE"
    assert mat.reload.unfinished_matches.first.loser2_name != "BYE"

    first_finals = matches.select{|m| m.bracket_position == "1/2"}.first
    third_finals = matches.select{|m| m.bracket_position == "3/4"}.first
    fifth_finals = matches.select{|m| m.bracket_position == "5/6"}.first

    assert first_finals.reload.wrestler1.name == "Test4"
    assert first_finals.reload.wrestler2.name == "Test2"

    assert third_finals.reload.wrestler1.name == "Test5"
    assert third_finals.reload.wrestler2.name == "Test1"

    test3_wrestler = @tournament.weights.first.wrestlers.select{|w| w.name == "Test3"}.first
    assert fifth_finals.reload.wrestler1.name == "Test3"
    assert fifth_finals.reload.loser2_name == "BYE"
    assert_equal test3_wrestler.id, fifth_finals.reload.winner_id


    # DEBUG
    # matches.sort_by{|m| m.bout_number}.each do |match|
    #   match.reload
    #   puts "Round #{match.round} #{match.w1_bracket_name} vs #{match.w2_bracket_name}"
    # end
  end
end