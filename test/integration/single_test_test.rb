require 'test_helper'

class SingleTestTest < ActionDispatch::IntegrationTest
  def setup
    @tournament = Tournament.find(1)
    # @tournament.generateMatchups
  end
  
  #rake test test/integration/single_test_test.rb > matches.txt
  def showMatches
    count = 1
    
    # Yml for matches
    # Match.where(tournament_id: 1).each do |m|
    #   puts "tournament_1_bout_#{m.bout_number}:"
    #   puts "   tournament_id: #{m.tournament_id}"
    #   puts "   weight_id: #{m.weight_id}"
    #   puts "   bout_number: #{m.bout_number}"
    #   puts "   w1: #{m.w1}"
    #   puts "   w2: #{m.w2}"
    #   puts "   bracket_position: #{m.bracket_position}"
    #   puts "   bracket_position_number: #{m.bracket_position_number}"
    #   puts "   loser1_name: #{m.loser1_name}"
    #   puts "   loser2_name: #{m.loser2_name}"
    #   puts "   round: #{m.round}"
    #   puts "   mat_id: #{m.mat_id}"
    #   puts "   finished: #{m.finished}"
    #   puts "   w1_stat: "
    #   puts "   w2_stat: "
    #   puts "   score: "
    #   puts "   winner_id: "
    #   puts "   win_type: "
    #   puts ""
    #   count += 1
    # end
    
    # Yml for wrestlers
    # @tournament.wrestlers.each do |w|
    #   puts "tournament_1_#{w.name}:"
    #   puts "   id: #{count}"
    #   puts "   name: #{w.name}"
    #   puts "   school_id: #{w.school_id}"
    #   puts "   weight_id: #{w.weight_id}"
    #   puts "   original_seed: #{w.original_seed}"
    #   puts "   season_loss: #{w.season_loss}"
    #   puts "   season_win: #{w.season_win}"
    #   puts "   criteria: #{w.criteria}"
    #   puts ""
    #   count += 1
    # end
  end
  
  test "the truth" do
    showMatches
    assert true
  end
end
