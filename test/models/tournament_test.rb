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
      number_of_wrestlers=1
      create_a_tournament_with_single_weight("Pool to bracket", number_of_wrestlers)
      assert @tournament.match_generation_error != nil
    end
    
    test "Tournament pool to bracket match generation errors with more than 24 wrestlers" do
      number_of_wrestlers=25
      create_a_tournament_with_single_weight("Pool to bracket", number_of_wrestlers)
      assert @tournament.match_generation_error != nil
    end
    
    test "Tournament pool to bracket no match generation errors with 24 wrestlers" do
      number_of_wrestlers=24
      create_a_tournament_with_single_weight("Pool to bracket", number_of_wrestlers)
      assert @tournament.match_generation_error == nil
    end
    
    test "Tournament pool to bracket no match generation errors with 2 wrestlers" do
      number_of_wrestlers=2
      create_a_tournament_with_single_weight("Pool to bracket", number_of_wrestlers)
      assert @tournament.match_generation_error == nil
    end
    
    # Modified 16 Man Double Elimination match_generation_error
    test "TournamentModified 16 Man Double Elimination match generation errors with less than 12 wrestlers" do
      number_of_wrestlers=11
      create_a_tournament_with_single_weight("Modified 16 Man Double Elimination", number_of_wrestlers)
      assert @tournament.match_generation_error != nil
    end
    
    test "Tournament Modified 16 Man Double Elimination match generation errors with more than 16 wrestlers" do
      number_of_wrestlers=17
      create_a_tournament_with_single_weight("Modified 16 Man Double Elimination", number_of_wrestlers)
      assert @tournament.match_generation_error != nil
    end
    
    test "Tournament Modified 16 Man Double Elimination no match generation errors with 16 wrestlers" do
      number_of_wrestlers=16
      create_a_tournament_with_single_weight("Modified 16 Man Double Elimination", number_of_wrestlers)
      assert @tournament.match_generation_error == nil
    end
    
    test "Tournament Modified 16 Man Double Elimination no match generation errors with 12 wrestlers" do
      number_of_wrestlers=12
      create_a_tournament_with_single_weight("Modified 16 Man Double Elimination", number_of_wrestlers)
      assert @tournament.match_generation_error == nil
    end
    
    # Double Elimination match_generation_error
    test "Tournament Double Elimination 1-8 match generation errors with less than 4 wrestlers" do
      number_of_wrestlers=3
      create_a_tournament_with_single_weight("Double Elimination 1-8", number_of_wrestlers)
      assert @tournament.match_generation_error != nil
    end
    
    test "Tournament Double Elimination 1-8 match generation errors with more than 16 wrestlers" do
      number_of_wrestlers=17
      create_a_tournament_with_single_weight("Double Elimination 1-8", number_of_wrestlers)
      assert @tournament.match_generation_error != nil
    end
    
    test "Tournament Double Elimination 1-8 no match generation errors with 16 wrestlers" do
      number_of_wrestlers=16
      create_a_tournament_with_single_weight("Double Elimination 1-8", number_of_wrestlers)
      assert @tournament.match_generation_error == nil
    end
    
    test "Tournament Double Elimination 1-8 no match generation errors with 4 wrestlers" do
      number_of_wrestlers=4
      create_a_tournament_with_single_weight("Double Elimination 1-8", number_of_wrestlers)
      assert @tournament.match_generation_error == nil
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
