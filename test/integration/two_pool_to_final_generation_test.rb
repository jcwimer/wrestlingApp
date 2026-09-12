# frozen_string_literal: true

require 'test_helper'

class TwoPoolToFinalGenerationTest < ActionDispatch::IntegrationTest
  def setup
    create_pool_tournament_single_weight(10)
  end

  test 'Match generation works' do
    assert @tournament.matches.count == 22
    assert(@tournament.matches.one? { |m| m.bracket_position == '1/2' })
    assert(@tournament.matches.one? { |m| m.bracket_position == '3/4' })
    assert @tournament.matches.count { |m| m.bracket_position == 'Pool' } == 20
    assert @tournament.weights.first.pools == 2
  end

  test 'Seeded wrestlers go to correct pool' do
    guy1 = get_wrestler_by_name('Test1')
    guy2 = get_wrestler_by_name('Test2')
    guy3 = get_wrestler_by_name('Test3')
    guy4 = get_wrestler_by_name('Test4')
    get_wrestler_by_name('Test5')
    get_wrestler_by_name('Test6')
    get_wrestler_by_name('Test7')
    get_wrestler_by_name('Test8')
    assert guy1.pool == 1
    assert guy2.pool == 2
    assert guy3.pool == 2
    assert guy4.pool == 1
  end

  test 'Loser names set up correctly' do
    assert @tournament.matches.find { |m| m.bracket_position == '1/2' && m.bracket_position_number == 1 }.loser1_name == 'Winner Pool 1'
    assert @tournament.matches.find { |m| m.bracket_position == '1/2' && m.bracket_position_number == 1 }.loser2_name == 'Winner Pool 2'
    assert @tournament.matches.find { |m| m.bracket_position == '3/4' && m.bracket_position_number == 1 }.loser1_name == 'Runner Up Pool 1'
    assert @tournament.matches.find { |m| m.bracket_position == '3/4' && m.bracket_position_number == 1 }.loser2_name == 'Runner Up Pool 2'
  end

  test 'Each wrestler has two pool matches' do
    @tournament.wrestlers.each do |wrestler|
      assert wrestler.pool_matches.size == 4
    end
  end

  test 'Run through all matches works' do
    @tournament.matches.sort_by(&:round).each do |match|
      match.winner_id = match.w1
      match.save
    end
    assert(@tournament.matches.none? { |m| m.finished == 0 })
  end
end
