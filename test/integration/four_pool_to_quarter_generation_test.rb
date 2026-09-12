# frozen_string_literal: true

require 'test_helper'

class FourPoolToQuarterGenerationTest < ActionDispatch::IntegrationTest
  def setup
    create_pool_tournament_single_weight(12)
  end

  test 'Match generation works' do
    assert @tournament.matches.count == 24
    assert @tournament.matches.count { |m| m.bracket_position == 'Quarter' } == 4
    assert @tournament.matches.count { |m| m.bracket_position == 'Semis' } == 2
    assert @tournament.matches.count { |m| m.bracket_position == 'Conso Semis' } == 2
    assert(@tournament.matches.one? { |m| m.bracket_position == '1/2' })
    assert(@tournament.matches.one? { |m| m.bracket_position == '3/4' })
    assert(@tournament.matches.one? { |m| m.bracket_position == '5/6' })
    assert(@tournament.matches.one? { |m| m.bracket_position == '7/8' })
    assert @tournament.matches.count { |m| m.bracket_position == 'Pool' } == 12
    assert @tournament.weights.first.pools == 4
  end

  test 'Seeded wrestlers go to correct pool' do
    guy1 = get_wrestler_by_name('Test1')
    guy2 = get_wrestler_by_name('Test2')
    guy3 = get_wrestler_by_name('Test3')
    guy4 = get_wrestler_by_name('Test4')
    guy5 = get_wrestler_by_name('Test5')
    guy6 = get_wrestler_by_name('Test6')
    guy7 = get_wrestler_by_name('Test7')
    guy8 = get_wrestler_by_name('Test8')
    assert guy1.pool == 1
    assert guy2.pool == 2
    assert guy3.pool == 3
    assert guy4.pool == 4
    assert guy5.pool == 4
    assert guy6.pool == 3
    assert guy7.pool == 2
    assert guy8.pool == 1
  end

  test 'Loser names set up correctly' do
    assert @tournament.matches.find { |m| m.bracket_position == 'Quarter' && m.bracket_position_number == 1 }.loser1_name == 'Winner Pool 1'
    assert @tournament.matches.find { |m| m.bracket_position == 'Quarter' && m.bracket_position_number == 1 }.loser2_name == 'Runner Up Pool 2'
    assert @tournament.matches.find { |m| m.bracket_position == 'Quarter' && m.bracket_position_number == 2 }.loser1_name == 'Winner Pool 4'
    assert @tournament.matches.find { |m| m.bracket_position == 'Quarter' && m.bracket_position_number == 2 }.loser2_name == 'Runner Up Pool 3'
    assert @tournament.matches.find { |m| m.bracket_position == 'Quarter' && m.bracket_position_number == 3 }.loser1_name == 'Winner Pool 2'
    assert @tournament.matches.find { |m| m.bracket_position == 'Quarter' && m.bracket_position_number == 3 }.loser2_name == 'Runner Up Pool 1'
    assert @tournament.matches.find { |m| m.bracket_position == 'Quarter' && m.bracket_position_number == 4 }.loser1_name == 'Winner Pool 3'
    assert @tournament.matches.find { |m| m.bracket_position == 'Quarter' && m.bracket_position_number == 4 }.loser2_name == 'Runner Up Pool 4'
    quarters = @tournament.matches.reload.select { |m| m.bracket_position == 'Quarter' }
    conso_semis_one = @tournament.matches.find do |match|
      match.bracket_position == 'Conso Semis' && match.bracket_position_number == 1
    end
    conso_semis_two = @tournament.matches.find do |match|
      match.bracket_position == 'Conso Semis' && match.bracket_position_number == 2
    end
    assert conso_semis_one.loser1_name == "Loser of #{quarters.find { |m| m.bracket_position_number == 1 }.bout_number}"
    assert conso_semis_one.loser2_name == "Loser of #{quarters.find { |m| m.bracket_position_number == 2 }.bout_number}"
    assert conso_semis_two.loser1_name == "Loser of #{quarters.find { |m| m.bracket_position_number == 3 }.bout_number}"
    assert conso_semis_two.loser2_name == "Loser of #{quarters.find { |m| m.bracket_position_number == 4 }.bout_number}"
    thirdFourth = @tournament.matches.reload.find { |m| m.bracket_position == '3/4' }
    seventhEighth = @tournament.matches.reload.find { |m| m.bracket_position == '7/8' }
    consoSemis = @tournament.matches.reload.select { |m| m.bracket_position == 'Conso Semis' }
    semis = @tournament.matches.reload.select { |m| m.bracket_position == 'Semis' }
    assert thirdFourth.loser1_name == "Loser of #{semis.find { |m| m.bracket_position_number == 1 }.bout_number}"
    assert thirdFourth.loser2_name == "Loser of #{semis.find { |m| m.bracket_position_number == 2 }.bout_number}"
    assert seventhEighth.loser1_name == "Loser of #{consoSemis.find { |m| m.bracket_position_number == 1 }.bout_number}"
    assert seventhEighth.loser2_name == "Loser of #{consoSemis.find { |m| m.bracket_position_number == 2 }.bout_number}"
  end

  test 'Each wrestler has two pool matches' do
    @tournament.wrestlers.each do |wrestler|
      assert wrestler.pool_matches.size == 2
    end
  end

  test 'Placement points are given when moving through bracket' do
    match = @tournament.matches.find { |m| m.bracket_position == 'Quarter' }
    wrestler = get_wrestler_by_name('Test1')
    match.w1 = wrestler.id
    match.save
    assert wrestler.reload.placement_points == 1

    match2 = @tournament.matches.find { |m| m.bracket_position == 'Semis' }
    match2.w1 = wrestler.id
    match2.save
    assert wrestler.reload.placement_points == 7
  end

  test 'Run through all matches works' do
    @tournament.matches.sort_by(&:round).each do |match|
      match.winner_id = match.w1
      match.save
    end
    assert(@tournament.matches.none? { |m| m.finished == 0 })
  end
end
