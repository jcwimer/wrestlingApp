require 'test_helper'

class TournamentTest < ActiveSupport::TestCase
  
  test "the truth" do
     assert true
   end
   
   test "Tournament validations" do
      tourney = Tournament.new
      assert_not tourney.valid?
      assert_equal [:date, :name, :tournament_type, :address, :director, :director_email], tourney.errors.attribute_names
    end
    
    # Pool to bracket match_generation_error
    test "Tournament pool to bracket match generation errors with less than two wrestlers" do
      create_a_tournament_with_single_weight("Pool to bracket", 1)
      assert_match("There is a tournament error.", @tournament.match_generation_error)
    end

    test "Tournament pool to bracket match generation errors with more than 24 wrestlers" do
      create_a_tournament_with_single_weight("Pool to bracket", 25)
      assert_match("There is a tournament error.", @tournament.match_generation_error)
    end

    test "Tournament pool to bracket no match generation errors with 24 wrestlers" do
      create_a_tournament_with_single_weight("Pool to bracket", 24)
      assert_nil @tournament.match_generation_error
    end

    test "Tournament pool to bracket no match generation errors with 2 wrestlers" do
      create_a_tournament_with_single_weight("Pool to bracket", 2)
      assert_nil @tournament.match_generation_error
    end

    # Modified 16 Man Double Elimination match_generation_error
    test "Tournament modified 16 man double elimination match generation errors with less than 12 wrestlers" do
      create_a_tournament_with_single_weight("Modified 16 Man Double Elimination", 11)
      assert_match("There is a tournament error.", @tournament.match_generation_error)
    end

    test "Tournament modified 16 man double elimination match generation errors with more than 16 wrestlers" do
      create_a_tournament_with_single_weight("Modified 16 Man Double Elimination", 17)
      assert_match("There is a tournament error.", @tournament.match_generation_error)
    end

    test "Tournament modified 16 man double elimination no match generation errors with 16 wrestlers" do
      create_a_tournament_with_single_weight("Modified 16 Man Double Elimination", 16)
      assert_nil @tournament.match_generation_error
    end

    test "Tournament modified 16 man double elimination no match generation errors with 12 wrestlers" do
      create_a_tournament_with_single_weight("Modified 16 Man Double Elimination", 12)
      assert_nil @tournament.match_generation_error
    end

    # Double Elimination match_generation_error
    test "Tournament regular double elimination 1-8 match generation errors with less than 2 wrestlers" do
      create_a_tournament_with_single_weight("Regular Double Elimination 1-8", 1)
      assert_match("There is a tournament error.", @tournament.match_generation_error)
    end

    test "Tournament regular double elimination 1-8 match generation errors with more than 64 wrestlers" do
      create_a_tournament_with_single_weight("Regular Double Elimination 1-8", 65)
      assert_match("There is a tournament error.", @tournament.match_generation_error)
    end

    test "Tournament regular double elimination 1-8 no match generation errors with 64 wrestlers" do
      create_a_tournament_with_single_weight("Regular Double Elimination 1-8", 64)
      assert_nil @tournament.match_generation_error
    end

    test "Tournament regular double elimination 1-8 no match generation errors with 2 wrestlers" do
      create_a_tournament_with_single_weight("Regular Double Elimination 1-8", 2)
      assert_nil @tournament.match_generation_error
    end

    test "Tournament match generation errors when a wrestler seed exceeds bracket size" do
      create_a_tournament_with_single_weight("Pool to bracket", 4)
      @tournament.weights.first.wrestlers.first.update!(original_seed: 8)
      assert_match("There is a tournament error.", @tournament.match_generation_error)
      assert_match("greater than the amount of wrestlers", @tournament.match_generation_error)
    end

    test "Tournament match generation errors when duplicate original seeds are present" do
      create_a_tournament_with_single_weight("Pool to bracket", 4)
      wrestlers = @tournament.weights.first.wrestlers.order(:id)
      wrestlers.first.update!(original_seed: 2)
      wrestlers.second.update!(original_seed: 2)
      assert_match("There is a tournament error.", @tournament.match_generation_error)
      assert_match("seeded 2", @tournament.match_generation_error)
    end

    test "Tournament match generation errors when original seeds are out of order" do
      create_a_tournament_with_single_weight("Pool to bracket", 4)
      wrestlers = @tournament.weights.first.wrestlers.order(:id)
      wrestlers.first.update!(original_seed: 1)
      wrestlers.second.update!(original_seed: 3)
      wrestlers.third.update!(original_seed: nil)
      wrestlers.fourth.update!(original_seed: nil)
      assert_match("There is a tournament error.", @tournament.match_generation_error)
      assert_match("out-of-order seeds", @tournament.match_generation_error)
    end

    ## End match_generation_error tests
    
    test "Tournament create_pre_defined_weights High School Boys Weights" do
      tournament = Tournament.find(1)
      tournament.create_pre_defined_weights(Weight::HS_WEIGHT_CLASSES.split(","))
      Weight::HS_WEIGHT_CLASSES.split(",").each do |weight|
          assert tournament.weights.select{|w| w.max == weight.to_i}.count == 1
      end
    end
    
    test "Tournament create_pre_defined_weights High School Girls Weights" do
      tournament = Tournament.find(1)
      tournament.create_pre_defined_weights(Weight::HS_GIRLS_WEIGHT_CLASSES.split(","))
      Weight::HS_GIRLS_WEIGHT_CLASSES.split(",").each do |weight|
          assert tournament.weights.select{|w| w.max == weight.to_i}.count == 1
      end
    end
    
    test "Tournament create_pre_defined_weights Middle School Boys Weights" do
      tournament = Tournament.find(1)
      tournament.create_pre_defined_weights(Weight::MS_WEIGHT_CLASSES.split(","))
      Weight::MS_WEIGHT_CLASSES.split(",").each do |weight|
          assert tournament.weights.select{|w| w.max == weight.to_i}.count == 1
      end
    end
    
    test "Tournament search_date_name returns results for all terms separately and non case sensitive" do
      tournament = Tournament.new
      tournament.name = "League Test Tournament D1"
      tournament.address = "some place"
      tournament.director = "some guy"
      tournament.director_email= "test@test.com"
      tournament.tournament_type = "Pool to bracket"
      tournament.date = "2015-12-30"
      tournament.save
      
      tournament = Tournament.new
      tournament.name = "League Test Tournament D2"
      tournament.address = "some place"
      tournament.director = "some guy"
      tournament.director_email= "test@test.com"
      tournament.tournament_type = "Pool to bracket"
      tournament.date = "2015-12-30"
      tournament.save
      
      tournament = Tournament.new
      tournament.name = "League Test Tournament D1"
      tournament.address = "some place"
      tournament.director = "some guy"
      tournament.director_email= "test@test.com"
      tournament.tournament_type = "Pool to bracket"
      tournament.date = "2016-12-30"
      tournament.save
      
      tournament = Tournament.new
      tournament.name = "League Test Tournament D2"
      tournament.address = "some place"
      tournament.director = "some guy"
      tournament.director_email= "test@test.com"
      tournament.tournament_type = "Pool to bracket"
      tournament.date = "2016-12-30"
      tournament.save
      
      tournament = Tournament.new
      tournament.name = "Test Tournament"
      tournament.address = "some place"
      tournament.director = "some guy"
      tournament.director_email= "test@test.com"
      tournament.tournament_type = "Pool to bracket"
      tournament.date = "2016-12-30"
      tournament.save
      
      tournaments = Tournament.limit(200).search_date_name("league 2016").order("date DESC")
      assert tournaments.count == 2
      tournaments.each do |tournament|
        assert tournament.date.to_s.include? "2016"
        assert tournament.name.include? "League"
      end
    end
end
