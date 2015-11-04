require 'test_helper'

class TournamentsControllerTest < ActionController::TestCase
include Devise::TestHelpers

  setup do
     @tournament = Tournament.find(1)
     @tournament.generateMatchups
     @school = @tournament.schools.first
  end

  def sign_in_owner
    sign_in users(:one)
  end

  def sign_in_non_owner
    sign_in users(:two)
  end

  def success
    assert_response :success
  end

  def redirect
    assert_redirected_to '/static_pages/not_allowed'
  end
  test "logged in tournament owner can generate matches" do
    sign_in_owner
    get :generate_matches, id: 1
    success
  end

  test "logged in non tournament owner cannot generate matches" do
    sign_in_non_owner
    get :generate_matches, id: 1
    redirect
  end

end
