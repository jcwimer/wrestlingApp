# frozen_string_literal: true

require 'test_helper'
require 'mocha/minitest'

class AutoMedicalForfeitTest < ActionDispatch::IntegrationTest
  DOUBLE_ELIMINATION_TYPES = [
    'Regular Double Elimination 1-6',
    'Regular Double Elimination 1-8',
    'Modified 16 Man Double Elimination 1-6',
    'Modified 16 Man Double Elimination 1-8'
  ].freeze

  def wrestler(name)
    @weight.wrestlers.find_by!(name: name)
  end

  def ready_match(bracket_position: nil)
    matches = Match.where(tournament_id: @tournament.id)
    matches = matches.where(bracket_position:) if bracket_position
    matches.order(:round, :bout_number).includes(:wrestler1, :wrestler2).find do |match|
      match.finished != 1 && match.w1 && match.w2
    end
  end

  def match_between(first_name, second_name)
    Match.where(tournament_id: @tournament.id).includes(:wrestler1, :wrestler2).find do |match|
      [match.wrestler1&.name, match.wrestler2&.name].compact.sort == [first_name, second_name].sort
    end
  end

  def finish_ready_matches(excluding: [])
    while (match = ready_match)
      participants = [match.wrestler1, match.wrestler2]
      assert_empty participants.map(&:name) & excluding
      end_match(match, match.wrestler1.name)
    end
  end

  def assert_medical_forfeit(match, winner_id: nil)
    match.reload
    assert_equal 1, match.finished
    assert_equal 'Medical Forfeit', match.win_type
    assert_equal '', match.score
    assert_not_nil match.finished_at
    assert_not_nil match.finalized_at
    assert_equal '(MFF)', match.bracket_score_string
    assert_predicate match, :valid?
    assert_equal winner_id, match.winner_id if winner_id
    assert_includes [match.w1, match.w2], match.winner_id
  end

  DOUBLE_ELIMINATION_TYPES.each do |tournament_type|
    test "medical forfeit advancement follows contested matches in #{tournament_type}" do
      create_double_elim_tournament_single_weight(8, tournament_type)
      medical_wrestler = wrestler('Test1')

      perform_enqueued_jobs { medical_wrestler.update!(auto_medical_forfeit: true) }
      finish_ready_matches(excluding: ['Test1'])

      medical_matches = Match.where(tournament_id: @tournament.id).where(w1: medical_wrestler.id)
                             .or(Match.where(tournament_id: @tournament.id, w2: medical_wrestler.id))
                             .where.not(w1: nil).where.not(w2: nil).to_a
      medical_matches.select! { |match| match.w1 == medical_wrestler.id || match.w2 == medical_wrestler.id }
      assert_operator medical_matches.size, :>=, 2

      medical_matches.each do |match|
        assert_medical_forfeit(match)
        opponent = Wrestler.find(([match.w1, match.w2] - [medical_wrestler.id]).first)
        assert_equal opponent.id, match.winner_id
        assert_equal 'L (MFF)', medical_wrestler.reload.result_by_bout(match.bout_number)
        assert_equal 'W (MFF)', opponent.result_by_bout(match.bout_number)
        assert_includes opponent.pin_wins.map(&:id), match.id
        assert_equal opponent.pin_wins.size * 2,
                     WrestlerServices::CalculateWrestlerTeamScore.new(opponent).bonus_win_points
      end
      unfinished_wrestler_ids = Match.where(tournament_id: @tournament.id).to_a
                                     .select { |match| match.finished != 1 && match.w1 && match.w2 }
                                     .flat_map { |match| [match.w1, match.w2] }.uniq
      assert_not_includes unfinished_wrestler_ids, medical_wrestler.id
    end
  end

  test 'a bye advances a marked wrestler and a later semifinal becomes a medical forfeit' do
    create_double_elim_tournament_single_weight(6, 'Regular Double Elimination 1-6')
    medical_wrestler = wrestler('Test1')
    bye_match = Match.where(tournament_id: @tournament.id).find do |match|
      match.winner_id == medical_wrestler.id && match.win_type == 'BYE'
    end
    assert_not_nil bye_match

    perform_enqueued_jobs { medical_wrestler.update!(auto_medical_forfeit: true) }

    semifinal = Match.where(tournament_id: @tournament.id, bracket_position: 'Semis')
                     .find { |match| [match.w1, match.w2].include?(medical_wrestler.id) }
    assert_not_nil semifinal
    assert_not_equal 1, semifinal.reload.finished
    assert_nil semifinal.winner_id
    assert_includes [semifinal.w1, semifinal.w2], medical_wrestler.id

    opponent_match = match_between('Test4', 'Test5')
    end_match(opponent_match, 'Test4')

    semifinal.reload
    assert_equal 'Test4', semifinal.winner.name
    assert_medical_forfeit(semifinal, winner_id: wrestler('Test4').id)
    assert_equal wrestler('Test1').id, bye_match.reload.winner_id
    assert_equal 'BYE', bye_match.win_type
  end

  test 'a wrestler marked before match generation automatically forfeits when assigned an opponent' do
    create_a_tournament_with_single_weight('Regular Double Elimination 1-8', 0)
    create_wrestlers_for_weight_for_double_elim(@weight, @school, 8, 1)
    medical_wrestler = wrestler('Test1')
    medical_wrestler.update!(auto_medical_forfeit: true)

    generate_tournament_matches(@tournament)

    medical_match = Match.where(tournament_id: @tournament.id).where.not(w1: nil).where.not(w2: nil).find do |match|
      (match.w1 == medical_wrestler.id || match.w2 == medical_wrestler.id) && match.w1 && match.w2
    end
    assert_not_nil medical_match
    opponent_id = ([medical_match.w1, medical_match.w2] - [medical_wrestler.id]).first
    assert_medical_forfeit(medical_match, winner_id: opponent_id)
  end

  test 'marking a pool wrestler only changes unfinished matches' do
    create_pool_tournament_single_weight(6)
    medical_wrestler = wrestler('Test1')
    first_match = medical_wrestler.pool_matches.first
    end_match(first_match, medical_wrestler.name)
    first_match.reload
    original_finalized_at = first_match.finalized_at

    perform_enqueued_jobs { medical_wrestler.update!(auto_medical_forfeit: true) }

    first_match.reload
    assert_equal 'Decision', first_match.win_type
    assert_equal original_finalized_at, first_match.finalized_at
    remaining_matches = medical_wrestler.reload.pool_matches.reject { |match| match.id == first_match.id }
    assert_equal 4, remaining_matches.size
    remaining_matches.each { |match| assert_medical_forfeit(match) }
  end

  test 'when both wrestlers are marked the medical forfeit winner is stable after a repeated job' do
    create_double_elim_tournament_single_weight(2, 'Regular Double Elimination 1-8')
    match = ready_match
    wrestler1 = Wrestler.find(match.w1)
    wrestler2 = Wrestler.find(match.w2)
    Wrestler.where(id: [wrestler1.id, wrestler2.id]).update_all(auto_medical_forfeit: true)

    Array.any_instance.expects(:sample).returns(wrestler2)
    2.times { AdvanceWrestlerJob.perform_now([match.id], @tournament.id) }

    assert_medical_forfeit(match, winner_id: wrestler2.id)
  end

  test 'medical forfeits route pool winners through the bracket without manually finishing them' do
    create_a_tournament_with_single_weight('Pool to bracket', 16)
    generate_tournament_matches(@tournament)
    medical_wrestler = wrestler('Test1')
    Match.where(tournament_id: @tournament.id, bracket_position: 'Pool')
         .where('w1 = :id OR w2 = :id', id: medical_wrestler.id).pluck(:id).each do |match_id|
      end_match(Match.find(match_id), medical_wrestler.name)
    end
    perform_enqueued_jobs { medical_wrestler.update!(auto_medical_forfeit: true) }

    while (match = ready_match(bracket_position: 'Pool'))
      assert_not_includes [match.wrestler1.name, match.wrestler2.name], medical_wrestler.name
      winner = [match.wrestler1, match.wrestler2].min_by(&:bracket_line)
      end_match(match, winner.name)
    end
    finish_ready_matches(excluding: [medical_wrestler.name])

    medical_wrestler.reload
    bracket_forfeits = medical_wrestler.all_matches.select do |match|
      match.bracket_position != 'Pool' && match.win_type == 'Medical Forfeit'
    end
    assert_operator bracket_forfeits.size, :>=, 2
    assert_equal 1, medical_wrestler.pool_placement
    bracket_forfeits.each { |match| assert_medical_forfeit(match) }
  end

  test 'generation finishes contested bouts when all double elimination wrestlers are marked' do
    create_a_tournament_with_single_weight('Regular Double Elimination 1-8', 8)
    @weight.wrestlers.order(:name).each_with_index { |entry, index| entry.update!(original_seed: index + 1) }
    @weight.wrestlers.update_all(auto_medical_forfeit: true)

    generate_tournament_matches(@tournament)

    contested_matches = Match.where(tournament_id: @tournament.id).where.not(w1: nil).where.not(w2: nil).to_a
    assert contested_matches.any?
    unfinished_matches = Match.where(tournament_id: @tournament.id).to_a.reject { |match| match.finished == 1 }
    assert_empty unfinished_matches
    contested_matches.each do |match|
      assert_medical_forfeit(match)
      assert_includes [match.w1, match.w2], match.winner_id
    end
  end

  test 'pool generation finishes all pool bouts when every wrestler is marked' do
    create_a_tournament_with_single_weight('Pool to bracket', 6)
    @weight.wrestlers.update_all(auto_medical_forfeit: true)

    generate_tournament_matches(@tournament)

    test1_pool_matches = Match.where(tournament_id: @tournament.id, bracket_position: 'Pool')
                              .where('w1 = :id OR w2 = :id', id: wrestler('Test1').id)
    assert_equal 5, test1_pool_matches.count
    test1_pool_matches.each { |match| assert_medical_forfeit(match) }
  end

  test 'turning off a medical forfeit leaves a waiting semifinal unfinished' do
    create_double_elim_tournament_single_weight(6, 'Regular Double Elimination 1-6')
    medical_wrestler = wrestler('Test1')
    perform_enqueued_jobs { medical_wrestler.update!(auto_medical_forfeit: true) }
    medical_wrestler.update!(auto_medical_forfeit: false)
    opponent_match = match_between('Test4', 'Test5')

    end_match(opponent_match, 'Test4')

    semifinal = Match.where(tournament_id: @tournament.id, bracket_position: 'Semis')
                     .find { |match| [match.w1, match.w2].include?(medical_wrestler.id) }
    assert_equal [medical_wrestler.id, wrestler('Test4').id].sort, [semifinal.w1, semifinal.w2].sort
    assert_not_equal 1, semifinal.reload.finished
    assert_nil semifinal.winner_id
  end

  test 'medical forfeit finalization removes its match from the mat queue' do
    create_double_elim_tournament_single_weight(4, 'Regular Double Elimination 1-6')
    mat = Mat.create!(name: 'Mat 1', tournament_id: @tournament.id)
    medical_wrestler = wrestler('Test1')
    match = ready_match
    mat.assign_match_to_queue!(match, 1)

    perform_enqueued_jobs { medical_wrestler.update!(auto_medical_forfeit: true) }

    match.reload
    mat.reload
    assert_medical_forfeit(match)
    assert_nil match.mat_id
    assert_not_equal match.id, mat.queue1
    queued_finished_matches = mat.queue_matches.compact.select { |queued_match| queued_match.finished == 1 }
    assert_empty queued_finished_matches
  end
end
