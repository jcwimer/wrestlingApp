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
end
