require 'test_helper'

class SchoolTest < ActiveSupport::TestCase
  test "the truth" do
     assert true
   end
   
   test "School validations" do
      school = School.new
      assert_not school.valid?
      assert_equal [:tournament,:name], school.errors.attribute_names
    end
end
