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
