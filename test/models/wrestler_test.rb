require 'test_helper'

class WrestlerTest < ActiveSupport::TestCase
   test "the truth" do
     assert true
   end
   
   test "Wrestler validations" do
      wrestler = Wrestler.new
      assert_not wrestler.valid?
      assert_equal [:name, :weight_id, :school_id], wrestler.errors.keys
    end
end
