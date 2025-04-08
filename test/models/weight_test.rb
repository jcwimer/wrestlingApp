require 'test_helper'

class WeightTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  
  test "Weight validations" do
    weight = Weight.new
    assert_not weight.valid?
    assert_equal [:max], weight.errors.attribute_names
  end
  
end
