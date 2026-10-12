# frozen_string_literal: true

require 'test_helper'

class SchoolTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  test 'School validations' do
    school = School.new
    assert_not school.valid?
    assert_equal %i[tournament name], school.errors.attribute_names
  end

  test 'email is optional and normalized' do
    school = schools(:one)

    assert school.update(email: '  COACH@Example.COM  ')
    assert_equal 'coach@example.com', school.email

    assert school.update(email: '   ')
    assert_equal '', school.email

    assert school.update(email: nil)
    assert_nil school.email
  end

  test 'invalid email is rejected' do
    school = schools(:one)

    assert_not school.update(email: 'not-an-email')
    assert_includes school.errors[:email], 'is invalid'
  end
end
