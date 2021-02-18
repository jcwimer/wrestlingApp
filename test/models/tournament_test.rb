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
end
