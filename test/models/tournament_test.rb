require 'test_helper'

class TournamentTest < ActiveSupport::TestCase
  test "the truth" do
     assert true
   end
   
   test "Tournament needs a date" do
      tourney = Tournament.new
      assert_not tourney.valid?
      assert_equal [:date], tourney.errors.keys
    end
end
