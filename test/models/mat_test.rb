require 'test_helper'

class MatTest < ActiveSupport::TestCase
 test "the truth" do
     assert true
   end
   
   test "Mat validations" do
      mat = Mat.new
      assert_not mat.valid?
      assert_equal [:tournament, :name], mat.errors.attribute_names
    end
end
