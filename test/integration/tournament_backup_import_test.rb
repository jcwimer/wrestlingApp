require 'test_helper'

class TournamentBackupImportTest < ActionDispatch::IntegrationTest
  def setup
  end

  def winner_by_name(winner_name,match)
    wrestler = @tournament.weights.first.wrestlers.select{|w| w.name == winner_name}.first
    match.winner_id = wrestler.id
    match.finished = 1
    match.win_type = "Decision"
    match.score = "1-0"
    match.save
  end

  test "Test backing up and importing a double elimination tournament mid tournament" do
    create_double_elim_tournament_single_weight(30, "Regular Double Elimination 1-8")

    # Setup mat and mat assignment rule
    mat = Mat.new(name: "Mat 1", tournament_id: @tournament.id)
    assert mat.save
    mat_assignment_rule = MatAssignmentRule.new(
      mat_id: mat.id,
      weight_classes: [@tournament.weights.first.id],
      rounds: [@tournament.matches.maximum(:round)],
      bracket_positions: ['1/2'],
      tournament_id: @tournament.id
    )
    assert mat_assignment_rule.save

    @tournament.reload

    # Copied from double_elimination_32_man_1_8_run_through_test.rb
    matches = @tournament.matches.reload

    round1 = matches.select{|m| m.round == 1}
    winner_by_name("Test17", round1.select{|m| m.bracket_position_number == 2}.first)
    winner_by_name("Test9", round1.select{|m| m.bracket_position_number == 3}.first)
    winner_by_name("Test25", round1.select{|m| m.bracket_position_number == 4}.first)
    winner_by_name("Test5", round1.select{|m| m.bracket_position_number == 5}.first)
    winner_by_name("Test12", round1.select{|m| m.bracket_position_number == 6}.first)
    winner_by_name("Test20", round1.select{|m| m.bracket_position_number == 7}.first)
    winner_by_name("Test4", round1.select{|m| m.bracket_position_number == 8}.first)
    winner_by_name("Test3", round1.select{|m| m.bracket_position_number == 9}.first)
    winner_by_name("Test14", round1.select{|m| m.bracket_position_number == 10}.first)
    winner_by_name("Test11", round1.select{|m| m.bracket_position_number == 11}.first)
    winner_by_name("Test6", round1.select{|m| m.bracket_position_number == 12}.first)
    winner_by_name("Test7", round1.select{|m| m.bracket_position_number == 13}.first)
    winner_by_name("Test10", round1.select{|m| m.bracket_position_number == 14}.first)
    winner_by_name("Test18", round1.select{|m| m.bracket_position_number == 15}.first)

    round2_championship = matches.reload.select{|m| m.bracket_position == "Bracket" and m.round == 2}.sort_by{|m| m.bracket_position_number}
    assert round2_championship.select{|m| m.bracket_position_number == 1}.first.reload.wrestler1.name == "Test1"
    assert round2_championship.select{|m| m.bracket_position_number == 1}.first.reload.wrestler2.name == "Test17"
    assert round2_championship.select{|m| m.bracket_position_number == 2}.first.reload.wrestler1.name == "Test9"
    assert round2_championship.select{|m| m.bracket_position_number == 2}.first.reload.wrestler2.name == "Test25"
    assert round2_championship.select{|m| m.bracket_position_number == 3}.first.reload.wrestler1.name == "Test5"
    assert round2_championship.select{|m| m.bracket_position_number == 3}.first.reload.wrestler2.name == "Test12"
    assert round2_championship.select{|m| m.bracket_position_number == 4}.first.reload.wrestler1.name == "Test20"
    assert round2_championship.select{|m| m.bracket_position_number == 4}.first.reload.wrestler2.name == "Test4"
    assert round2_championship.select{|m| m.bracket_position_number == 5}.first.reload.wrestler1.name == "Test3"
    assert round2_championship.select{|m| m.bracket_position_number == 5}.first.reload.wrestler2.name == "Test14"
    assert round2_championship.select{|m| m.bracket_position_number == 6}.first.reload.wrestler1.name == "Test11"
    assert round2_championship.select{|m| m.bracket_position_number == 6}.first.reload.wrestler2.name == "Test6"
    assert round2_championship.select{|m| m.bracket_position_number == 7}.first.reload.wrestler1.name == "Test7"
    assert round2_championship.select{|m| m.bracket_position_number == 7}.first.reload.wrestler2.name == "Test10"
    assert round2_championship.select{|m| m.bracket_position_number == 8}.first.reload.wrestler1.name == "Test18"
    assert round2_championship.select{|m| m.bracket_position_number == 8}.first.reload.wrestler2.name == "Test2"
    winner_by_name("Test1", round2_championship.select{|m| m.bracket_position_number == 1}.first)
    winner_by_name("Test25", round2_championship.select{|m| m.bracket_position_number == 2}.first)
    winner_by_name("Test5", round2_championship.select{|m| m.bracket_position_number == 3}.first)
    winner_by_name("Test4", round2_championship.select{|m| m.bracket_position_number == 4}.first)
    winner_by_name("Test3", round2_championship.select{|m| m.bracket_position_number == 5}.first)
    winner_by_name("Test11", round2_championship.select{|m| m.bracket_position_number == 6}.first)
    winner_by_name("Test10", round2_championship.select{|m| m.bracket_position_number == 7}.first)
    winner_by_name("Test2", round2_championship.select{|m| m.bracket_position_number == 8}.first)

    round2_conso = matches.reload.select{|m| m.bracket_position == "Conso" and m.round == 2}.sort_by{|m| m.bracket_position_number}
    assert round2_conso.select{|m| m.bracket_position_number == 1}.first.reload.loser1_name == "BYE"
    assert round2_conso.select{|m| m.bracket_position_number == 1}.first.reload.wrestler2.name == "Test16"
    assert round2_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler1.name == "Test24"
    assert round2_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler2.name == "Test8"
    assert round2_conso.select{|m| m.bracket_position_number == 3}.first.reload.wrestler1.name == "Test28"
    assert round2_conso.select{|m| m.bracket_position_number == 3}.first.reload.wrestler2.name == "Test21"
    assert round2_conso.select{|m| m.bracket_position_number == 4}.first.reload.wrestler1.name == "Test13"
    assert round2_conso.select{|m| m.bracket_position_number == 4}.first.reload.wrestler2.name == "Test29"
    assert round2_conso.select{|m| m.bracket_position_number == 5}.first.reload.wrestler1.name == "Test30"
    assert round2_conso.select{|m| m.bracket_position_number == 5}.first.reload.wrestler2.name == "Test19"
    assert round2_conso.select{|m| m.bracket_position_number == 6}.first.reload.wrestler1.name == "Test22"
    assert round2_conso.select{|m| m.bracket_position_number == 6}.first.reload.wrestler2.name == "Test27"
    assert round2_conso.select{|m| m.bracket_position_number == 7}.first.reload.wrestler1.name == "Test26"
    assert round2_conso.select{|m| m.bracket_position_number == 7}.first.reload.wrestler2.name == "Test23"
    assert round2_conso.select{|m| m.bracket_position_number == 8}.first.reload.wrestler1.name == "Test15"
    assert round2_conso.select{|m| m.bracket_position_number == 8}.first.reload.loser2_name == "BYE"
    winner_by_name("Test8", round2_conso.select{|m| m.bracket_position_number == 2}.first)
    winner_by_name("Test21", round2_conso.select{|m| m.bracket_position_number == 3}.first)
    winner_by_name("Test29", round2_conso.select{|m| m.bracket_position_number == 4}.first)
    winner_by_name("Test19", round2_conso.select{|m| m.bracket_position_number == 5}.first)
    winner_by_name("Test22", round2_conso.select{|m| m.bracket_position_number == 6}.first)
    winner_by_name("Test23", round2_conso.select{|m| m.bracket_position_number == 7}.first)

    round3_conso = matches.reload.select{|m| m.bracket_position == "Conso" and m.round == 3}.sort_by{|m| m.bracket_position_number}
    assert round3_conso.select{|m| m.bracket_position_number == 1}.first.reload.wrestler1.name == "Test18"
    assert round3_conso.select{|m| m.bracket_position_number == 1}.first.reload.wrestler2.name == "Test16"
    assert round3_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler1.name == "Test7"
    assert round3_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler2.name == "Test8"
    assert round3_conso.select{|m| m.bracket_position_number == 3}.first.reload.wrestler1.name == "Test6"
    assert round3_conso.select{|m| m.bracket_position_number == 3}.first.reload.wrestler2.name == "Test21"
    assert round3_conso.select{|m| m.bracket_position_number == 4}.first.reload.wrestler1.name == "Test14"
    assert round3_conso.select{|m| m.bracket_position_number == 4}.first.reload.wrestler2.name == "Test29"
    assert round3_conso.select{|m| m.bracket_position_number == 5}.first.reload.wrestler1.name == "Test20"
    assert round3_conso.select{|m| m.bracket_position_number == 5}.first.reload.wrestler2.name == "Test19"
    assert round3_conso.select{|m| m.bracket_position_number == 6}.first.reload.wrestler1.name == "Test12"
    assert round3_conso.select{|m| m.bracket_position_number == 6}.first.reload.wrestler2.name == "Test22"
    assert round3_conso.select{|m| m.bracket_position_number == 7}.first.reload.wrestler1.name == "Test9"
    assert round3_conso.select{|m| m.bracket_position_number == 7}.first.reload.wrestler2.name == "Test23"
    assert round3_conso.select{|m| m.bracket_position_number == 8}.first.reload.wrestler1.name == "Test17"
    assert round3_conso.select{|m| m.bracket_position_number == 8}.first.reload.wrestler2.name == "Test15"
    winner_by_name("Test16", round3_conso.select{|m| m.bracket_position_number == 1}.first)
    winner_by_name("Test8", round3_conso.select{|m| m.bracket_position_number == 2}.first)
    winner_by_name("Test6", round3_conso.select{|m| m.bracket_position_number == 3}.first)
    winner_by_name("Test29", round3_conso.select{|m| m.bracket_position_number == 4}.first)
    winner_by_name("Test20", round3_conso.select{|m| m.bracket_position_number == 5}.first)
    winner_by_name("Test12", round3_conso.select{|m| m.bracket_position_number == 6}.first)
    winner_by_name("Test23", round3_conso.select{|m| m.bracket_position_number == 7}.first)
    winner_by_name("Test17", round3_conso.select{|m| m.bracket_position_number == 8}.first)

    round4_conso = matches.reload.select{|m| m.bracket_position == "Conso" and m.round == 4}.sort_by{|m| m.bracket_position_number}
    assert round4_conso.select{|m| m.bracket_position_number == 1}.first.reload.wrestler1.name == "Test16"
    assert round4_conso.select{|m| m.bracket_position_number == 1}.first.reload.wrestler2.name == "Test8"
    assert round4_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler1.name == "Test6"
    assert round4_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler2.name == "Test29"
    assert round4_conso.select{|m| m.bracket_position_number == 3}.first.reload.wrestler1.name == "Test20"
    assert round4_conso.select{|m| m.bracket_position_number == 3}.first.reload.wrestler2.name == "Test12"
    assert round4_conso.select{|m| m.bracket_position_number == 4}.first.reload.wrestler1.name == "Test23"
    assert round4_conso.select{|m| m.bracket_position_number == 4}.first.reload.wrestler2.name == "Test17"
    winner_by_name("Test8", round4_conso.select{|m| m.bracket_position_number == 1}.first)
    winner_by_name("Test6", round4_conso.select{|m| m.bracket_position_number == 2}.first)
    winner_by_name("Test20", round4_conso.select{|m| m.bracket_position_number == 3}.first)
    winner_by_name("Test17", round4_conso.select{|m| m.bracket_position_number == 4}.first)

    quarters = matches.reload.select{|m| m.bracket_position == "Quarter"}.sort_by{|m| m.bracket_position_number}
    assert quarters.select{|m| m.bracket_position_number == 1}.first.reload.wrestler1.name == "Test1"
    assert quarters.select{|m| m.bracket_position_number == 1}.first.reload.wrestler2.name == "Test25"
    assert quarters.select{|m| m.bracket_position_number == 2}.first.reload.wrestler1.name == "Test5"
    assert quarters.select{|m| m.bracket_position_number == 2}.first.reload.wrestler2.name == "Test4"
    assert quarters.select{|m| m.bracket_position_number == 3}.first.reload.wrestler1.name == "Test3"
    assert quarters.select{|m| m.bracket_position_number == 3}.first.reload.wrestler2.name == "Test11"
    assert quarters.select{|m| m.bracket_position_number == 4}.first.reload.wrestler1.name == "Test10"
    assert quarters.select{|m| m.bracket_position_number == 4}.first.reload.wrestler2.name == "Test2"
    winner_by_name("Test1", quarters.select{|m| m.bracket_position_number == 1}.first)
    winner_by_name("Test5", quarters.select{|m| m.bracket_position_number == 2}.first)
    winner_by_name("Test11", quarters.select{|m| m.bracket_position_number == 3}.first)
    winner_by_name("Test2", quarters.select{|m| m.bracket_position_number == 4}.first)

    round5_conso = matches.reload.select{|m| m.bracket_position == "Conso" and m.round == 5}.sort_by{|m| m.bracket_position_number}
    assert round5_conso.select{|m| m.bracket_position_number == 1}.first.reload.wrestler1.name == "Test25"
    assert round5_conso.select{|m| m.bracket_position_number == 1}.first.reload.wrestler2.name == "Test8"
    assert round5_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler1.name == "Test4"
    assert round5_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler2.name == "Test6"
    assert round5_conso.select{|m| m.bracket_position_number == 3}.first.reload.wrestler1.name == "Test3"
    assert round5_conso.select{|m| m.bracket_position_number == 3}.first.reload.wrestler2.name == "Test20"
    assert round5_conso.select{|m| m.bracket_position_number == 4}.first.reload.wrestler1.name == "Test10"
    assert round5_conso.select{|m| m.bracket_position_number == 4}.first.reload.wrestler2.name == "Test17"
    winner_by_name("Test8", round5_conso.select{|m| m.bracket_position_number == 1}.first)
    winner_by_name("Test6", round5_conso.select{|m| m.bracket_position_number == 2}.first)
    winner_by_name("Test3", round5_conso.select{|m| m.bracket_position_number == 3}.first)
    winner_by_name("Test10", round5_conso.select{|m| m.bracket_position_number == 4}.first)

    quarters_conso = matches.reload.select{|m| m.bracket_position == "Conso Quarter"}.sort_by{|m| m.bracket_position_number}
    assert quarters_conso.select{|m| m.bracket_position_number == 1}.first.reload.wrestler1.name == "Test8"
    assert quarters_conso.select{|m| m.bracket_position_number == 1}.first.reload.wrestler2.name == "Test6"
    assert quarters_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler1.name == "Test3"
    assert quarters_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler2.name == "Test10"
    winner_by_name("Test8", quarters_conso.select{|m| m.bracket_position_number == 1}.first)
    winner_by_name("Test3", quarters_conso.select{|m| m.bracket_position_number == 2}.first)

    semis = matches.reload.select{|m| m.bracket_position == "Semis"}.sort_by{|m| m.bracket_position_number}
    assert semis.select{|m| m.bracket_position_number == 1}.first.reload.wrestler1.name == "Test1"
    assert semis.select{|m| m.bracket_position_number == 1}.first.reload.wrestler2.name == "Test5"
    assert semis.select{|m| m.bracket_position_number == 2}.first.reload.wrestler1.name == "Test11"
    assert semis.select{|m| m.bracket_position_number == 2}.first.reload.wrestler2.name == "Test2"
    winner_by_name("Test5", semis.select{|m| m.bracket_position_number == 1}.first)
    winner_by_name("Test2", semis.select{|m| m.bracket_position_number == 2}.first)

    semis_conso = matches.reload.select{|m| m.bracket_position == "Conso Semis"}.sort_by{|m| m.bracket_position_number}
    assert semis_conso.select{|m| m.bracket_position_number == 1}.first.reload.wrestler1.name == "Test11"
    assert semis_conso.select{|m| m.bracket_position_number == 1}.first.reload.wrestler2.name == "Test8"
    assert semis_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler1.name == "Test1"
    assert semis_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler2.name == "Test3"
    winner_by_name("Test11", semis_conso.select{|m| m.bracket_position_number == 1}.first)
    winner_by_name("Test3", semis_conso.select{|m| m.bracket_position_number == 2}.first)

    first_finals = matches.select{|m| m.bracket_position == "1/2"}.first
    third_finals = matches.select{|m| m.bracket_position == "3/4"}.first
    fifth_finals = matches.select{|m| m.bracket_position == "5/6"}.first
    seventh_finals = matches.select{|m| m.bracket_position == "7/8"}.first

    assert first_finals.reload.wrestler1.name == "Test5"
    assert first_finals.reload.wrestler2.name == "Test2"

    assert third_finals.reload.wrestler1.name == "Test11"
    assert third_finals.reload.wrestler2.name == "Test3"

    assert fifth_finals.reload.wrestler1.name == "Test8"
    assert fifth_finals.reload.wrestler2.name == "Test1"
    
    assert seventh_finals.reload.wrestler1.name == "Test6"
    assert seventh_finals.reload.wrestler2.name == "Test10"

    # Backup, then restore, then run asserts again
    TournamentBackupService.new(@tournament, 'Manual backup').create_backup
    backup = TournamentBackup.where(tournament: @tournament).first
    WrestlingdevImporter.new(@tournament, backup).import

    @tournament.reload

    # Assert non match things
    assert_equal "Mat 1", @tournament.mats.first.name

    mat_assignment_rule = @tournament.mats.first.mat_assignment_rules.first
    assert mat_assignment_rule.weight_classes == [@tournament.weights.first.id]
    assert mat_assignment_rule.bracket_positions == ["1/2"]
    assert mat_assignment_rule.rounds == [@tournament.matches.maximum(:round)]
    assert mat_assignment_rule.mat_id == @tournament.mats.first.id

    # Re-run the same asserts as above
    matches = @tournament.matches.reload
    round2_championship = matches.reload.select{|m| m.bracket_position == "Bracket" and m.round == 2}.sort_by{|m| m.bracket_position_number}
    assert round2_championship.select{|m| m.bracket_position_number == 1}.first.reload.wrestler1.name == "Test1"
    assert round2_championship.select{|m| m.bracket_position_number == 1}.first.reload.wrestler2.name == "Test17"
    assert round2_championship.select{|m| m.bracket_position_number == 2}.first.reload.wrestler1.name == "Test9"
    assert round2_championship.select{|m| m.bracket_position_number == 2}.first.reload.wrestler2.name == "Test25"
    assert round2_championship.select{|m| m.bracket_position_number == 3}.first.reload.wrestler1.name == "Test5"
    assert round2_championship.select{|m| m.bracket_position_number == 3}.first.reload.wrestler2.name == "Test12"
    assert round2_championship.select{|m| m.bracket_position_number == 4}.first.reload.wrestler1.name == "Test20"
    assert round2_championship.select{|m| m.bracket_position_number == 4}.first.reload.wrestler2.name == "Test4"
    assert round2_championship.select{|m| m.bracket_position_number == 5}.first.reload.wrestler1.name == "Test3"
    assert round2_championship.select{|m| m.bracket_position_number == 5}.first.reload.wrestler2.name == "Test14"
    assert round2_championship.select{|m| m.bracket_position_number == 6}.first.reload.wrestler1.name == "Test11"
    assert round2_championship.select{|m| m.bracket_position_number == 6}.first.reload.wrestler2.name == "Test6"
    assert round2_championship.select{|m| m.bracket_position_number == 7}.first.reload.wrestler1.name == "Test7"
    assert round2_championship.select{|m| m.bracket_position_number == 7}.first.reload.wrestler2.name == "Test10"
    assert round2_championship.select{|m| m.bracket_position_number == 8}.first.reload.wrestler1.name == "Test18"
    assert round2_championship.select{|m| m.bracket_position_number == 8}.first.reload.wrestler2.name == "Test2"

    round2_conso = matches.reload.select{|m| m.bracket_position == "Conso" and m.round == 2}.sort_by{|m| m.bracket_position_number}
    assert round2_conso.select{|m| m.bracket_position_number == 1}.first.reload.loser1_name == "BYE"
    assert round2_conso.select{|m| m.bracket_position_number == 1}.first.reload.wrestler2.name == "Test16"
    assert round2_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler1.name == "Test24"
    assert round2_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler2.name == "Test8"
    assert round2_conso.select{|m| m.bracket_position_number == 3}.first.reload.wrestler1.name == "Test28"
    assert round2_conso.select{|m| m.bracket_position_number == 3}.first.reload.wrestler2.name == "Test21"
    assert round2_conso.select{|m| m.bracket_position_number == 4}.first.reload.wrestler1.name == "Test13"
    assert round2_conso.select{|m| m.bracket_position_number == 4}.first.reload.wrestler2.name == "Test29"
    assert round2_conso.select{|m| m.bracket_position_number == 5}.first.reload.wrestler1.name == "Test30"
    assert round2_conso.select{|m| m.bracket_position_number == 5}.first.reload.wrestler2.name == "Test19"
    assert round2_conso.select{|m| m.bracket_position_number == 6}.first.reload.wrestler1.name == "Test22"
    assert round2_conso.select{|m| m.bracket_position_number == 6}.first.reload.wrestler2.name == "Test27"
    assert round2_conso.select{|m| m.bracket_position_number == 7}.first.reload.wrestler1.name == "Test26"
    assert round2_conso.select{|m| m.bracket_position_number == 7}.first.reload.wrestler2.name == "Test23"
    assert round2_conso.select{|m| m.bracket_position_number == 8}.first.reload.wrestler1.name == "Test15"
    assert round2_conso.select{|m| m.bracket_position_number == 8}.first.reload.loser2_name == "BYE"

    round3_conso = matches.reload.select{|m| m.bracket_position == "Conso" and m.round == 3}.sort_by{|m| m.bracket_position_number}
    assert round3_conso.select{|m| m.bracket_position_number == 1}.first.reload.wrestler1.name == "Test18"
    assert round3_conso.select{|m| m.bracket_position_number == 1}.first.reload.wrestler2.name == "Test16"
    assert round3_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler1.name == "Test7"
    assert round3_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler2.name == "Test8"
    assert round3_conso.select{|m| m.bracket_position_number == 3}.first.reload.wrestler1.name == "Test6"
    assert round3_conso.select{|m| m.bracket_position_number == 3}.first.reload.wrestler2.name == "Test21"
    assert round3_conso.select{|m| m.bracket_position_number == 4}.first.reload.wrestler1.name == "Test14"
    assert round3_conso.select{|m| m.bracket_position_number == 4}.first.reload.wrestler2.name == "Test29"
    assert round3_conso.select{|m| m.bracket_position_number == 5}.first.reload.wrestler1.name == "Test20"
    assert round3_conso.select{|m| m.bracket_position_number == 5}.first.reload.wrestler2.name == "Test19"
    assert round3_conso.select{|m| m.bracket_position_number == 6}.first.reload.wrestler1.name == "Test12"
    assert round3_conso.select{|m| m.bracket_position_number == 6}.first.reload.wrestler2.name == "Test22"
    assert round3_conso.select{|m| m.bracket_position_number == 7}.first.reload.wrestler1.name == "Test9"
    assert round3_conso.select{|m| m.bracket_position_number == 7}.first.reload.wrestler2.name == "Test23"
    assert round3_conso.select{|m| m.bracket_position_number == 8}.first.reload.wrestler1.name == "Test17"
    assert round3_conso.select{|m| m.bracket_position_number == 8}.first.reload.wrestler2.name == "Test15"

    round4_conso = matches.reload.select{|m| m.bracket_position == "Conso" and m.round == 4}.sort_by{|m| m.bracket_position_number}
    assert round4_conso.select{|m| m.bracket_position_number == 1}.first.reload.wrestler1.name == "Test16"
    assert round4_conso.select{|m| m.bracket_position_number == 1}.first.reload.wrestler2.name == "Test8"
    assert round4_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler1.name == "Test6"
    assert round4_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler2.name == "Test29"
    assert round4_conso.select{|m| m.bracket_position_number == 3}.first.reload.wrestler1.name == "Test20"
    assert round4_conso.select{|m| m.bracket_position_number == 3}.first.reload.wrestler2.name == "Test12"
    assert round4_conso.select{|m| m.bracket_position_number == 4}.first.reload.wrestler1.name == "Test23"
    assert round4_conso.select{|m| m.bracket_position_number == 4}.first.reload.wrestler2.name == "Test17"

    quarters = matches.reload.select{|m| m.bracket_position == "Quarter"}.sort_by{|m| m.bracket_position_number}
    assert quarters.select{|m| m.bracket_position_number == 1}.first.reload.wrestler1.name == "Test1"
    assert quarters.select{|m| m.bracket_position_number == 1}.first.reload.wrestler2.name == "Test25"
    assert quarters.select{|m| m.bracket_position_number == 2}.first.reload.wrestler1.name == "Test5"
    assert quarters.select{|m| m.bracket_position_number == 2}.first.reload.wrestler2.name == "Test4"
    assert quarters.select{|m| m.bracket_position_number == 3}.first.reload.wrestler1.name == "Test3"
    assert quarters.select{|m| m.bracket_position_number == 3}.first.reload.wrestler2.name == "Test11"
    assert quarters.select{|m| m.bracket_position_number == 4}.first.reload.wrestler1.name == "Test10"
    assert quarters.select{|m| m.bracket_position_number == 4}.first.reload.wrestler2.name == "Test2"

    round5_conso = matches.reload.select{|m| m.bracket_position == "Conso" and m.round == 5}.sort_by{|m| m.bracket_position_number}
    assert round5_conso.select{|m| m.bracket_position_number == 1}.first.reload.wrestler1.name == "Test25"
    assert round5_conso.select{|m| m.bracket_position_number == 1}.first.reload.wrestler2.name == "Test8"
    assert round5_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler1.name == "Test4"
    assert round5_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler2.name == "Test6"
    assert round5_conso.select{|m| m.bracket_position_number == 3}.first.reload.wrestler1.name == "Test3"
    assert round5_conso.select{|m| m.bracket_position_number == 3}.first.reload.wrestler2.name == "Test20"
    assert round5_conso.select{|m| m.bracket_position_number == 4}.first.reload.wrestler1.name == "Test10"
    assert round5_conso.select{|m| m.bracket_position_number == 4}.first.reload.wrestler2.name == "Test17"

    quarters_conso = matches.reload.select{|m| m.bracket_position == "Conso Quarter"}.sort_by{|m| m.bracket_position_number}
    assert quarters_conso.select{|m| m.bracket_position_number == 1}.first.reload.wrestler1.name == "Test8"
    assert quarters_conso.select{|m| m.bracket_position_number == 1}.first.reload.wrestler2.name == "Test6"
    assert quarters_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler1.name == "Test3"
    assert quarters_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler2.name == "Test10"

    semis = matches.reload.select{|m| m.bracket_position == "Semis"}.sort_by{|m| m.bracket_position_number}
    assert semis.select{|m| m.bracket_position_number == 1}.first.reload.wrestler1.name == "Test1"
    assert semis.select{|m| m.bracket_position_number == 1}.first.reload.wrestler2.name == "Test5"
    assert semis.select{|m| m.bracket_position_number == 2}.first.reload.wrestler1.name == "Test11"
    assert semis.select{|m| m.bracket_position_number == 2}.first.reload.wrestler2.name == "Test2"

    semis_conso = matches.reload.select{|m| m.bracket_position == "Conso Semis"}.sort_by{|m| m.bracket_position_number}
    assert semis_conso.select{|m| m.bracket_position_number == 1}.first.reload.wrestler1.name == "Test11"
    assert semis_conso.select{|m| m.bracket_position_number == 1}.first.reload.wrestler2.name == "Test8"
    assert semis_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler1.name == "Test1"
    assert semis_conso.select{|m| m.bracket_position_number == 2}.first.reload.wrestler2.name == "Test3"

    first_finals = matches.select{|m| m.bracket_position == "1/2"}.first
    third_finals = matches.select{|m| m.bracket_position == "3/4"}.first
    fifth_finals = matches.select{|m| m.bracket_position == "5/6"}.first
    seventh_finals = matches.select{|m| m.bracket_position == "7/8"}.first

    assert first_finals.reload.wrestler1.name == "Test5"
    assert first_finals.reload.wrestler2.name == "Test2"

    assert third_finals.reload.wrestler1.name == "Test11"
    assert third_finals.reload.wrestler2.name == "Test3"

    assert fifth_finals.reload.wrestler1.name == "Test8"
    assert fifth_finals.reload.wrestler2.name == "Test1"
    
    assert seventh_finals.reload.wrestler1.name == "Test6"
    assert seventh_finals.reload.wrestler2.name == "Test10"
  end

  test "Test backing up and importing a mat and mat assignment rules" do
    create_double_elim_tournament_single_weight(30, "Regular Double Elimination 1-8")
  
    mat = Mat.create!(name: "Mat 1", tournament_id: @tournament.id)
    MatAssignmentRule.create!(
      mat_id: mat.id,
      weight_classes: [@tournament.weights.first.id],
      rounds: [@tournament.matches.maximum(:round)],
      bracket_positions: ['1/2'],
      tournament_id: @tournament.id
    )
  
    # Backup and import
    TournamentBackupService.new(@tournament, 'Manual backup').create_backup
    backup = TournamentBackup.where(tournament: @tournament).first
    WrestlingdevImporter.new(@tournament, backup).import
  
    @tournament.reload
    assert_equal "Mat 1", @tournament.mats.first.name

    mat_assignment_rule = @tournament.mats.first.mat_assignment_rules.first
    assert mat_assignment_rule.weight_classes == [@tournament.weights.first.id]
    assert mat_assignment_rule.bracket_positions == ["1/2"]
    assert mat_assignment_rule.rounds == [@tournament.matches.maximum(:round)]
    assert mat_assignment_rule.mat_id == @tournament.mats.first.id
  end

  test "Backing up and importing a very large tournament" do
    create_double_elim_tournament_1_6_with_multiple_weights_and_multiple_mats(32, 14, 6) # 6 wrestlers, 5 weights, 3 mats
    @tournament.reload
    original_number_of_matches = @tournament.matches.count
    original_number_of_mats = @tournament.mats.count
    original_number_of_wrestlers = @tournament.wrestlers.count
    original_number_of_weights = @tournament.weights.count
    original_number_of_schools = @tournament.schools.count

    @tournament.matches.each do |match|
        match.w1_stat = "T2 |End Period| |Deferred| R2 N2 |End Period| |Chose Neutral| P1 E1 E1 E1 |End Period|"
        match.w2_stat = "E1 T2 S |End Period| |Chose Neutral| T2 N3 |End Period| T2 S T2 T2 |End Period|"
        match.save
    end

    TournamentBackupService.new(@tournament, 'Manual backup').create_backup
    backup = TournamentBackup.where(tournament: @tournament).first
    # puts "Backup size in bytes: #{backup.backup_data.bytesize}"
    # 1253119 (~1.25 MB) vs 4294967295 max (4 GB)
    WrestlingdevImporter.new(@tournament, backup).import
  
    @tournament.reload

    assert @tournament.matches.reload.count == original_number_of_matches
    assert @tournament.mats.reload.count == original_number_of_mats
    assert @tournament.wrestlers.reload.count == original_number_of_wrestlers
    assert @tournament.weights.reload.count == original_number_of_weights
    assert @tournament.schools.reload.count == original_number_of_schools
  end
end