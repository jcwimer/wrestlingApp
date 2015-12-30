require 'test_helper'

class SchoolTest < ActiveSupport::TestCase
  test "the truth" do
     assert true
   end
   
   test "School validations" do
      school = School.new
      assert_not school.valid?
      assert_equal [:name], school.errors.keys
    end
end
