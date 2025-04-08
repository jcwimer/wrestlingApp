require 'test_helper'

class StaticPagesControllerTest < ActionController::TestCase
  # Remove Devise helpers since we're no longer using Devise
  # include Devise::Test::ControllerHelpers

  setup do
     @tournament = Tournament.find(1)
    # @tournament.generateMatchups
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

  test "get root page" do
    get :home
    success
  end

  test "get my_tournaments" do
    sign_in_owner
    get :my_tournaments  
    success
  end
end
