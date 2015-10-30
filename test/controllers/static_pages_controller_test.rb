require 'test_helper'

class StaticPagesControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  setup do
     @tournament = Tournament.find(1)
     @tournament.generateMatchups
     @school = @tournament.schools.first
  end
 
  def new
    get :new, tournament: @tournament.id
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
    get :generate_matches, tournament: 1
    success
  end

  test "logged in non tournament owner cannot generate matches" do
    sign_in_non_owner
    get :generate_matches, tournament: 1
    redirect
  end

  test "logged in tournament owner can access weigh_ins" do
    sign_in_owner
    get :weigh_in, tournament: 1
    success
  end

  test "logged in non tournament owner cannot access weigh_ins" do
    sign_in_non_owner
    get :weigh_in, tournament: 1
    redirect    
  end

  test "logged in tournament owner can create custom weights" do
    sign_in_owner
    get :createCustomWeights, tournament: 1, customValue: 'hs' 
    assert_redirected_to '/tournaments/1'
  end

  test "logged in non tournament owner cannot create custom weights" do
    sign_in_non_owner
    get :createCustomWeights, tournament: 1, customValue: 'hs' 
    redirect
  end

end
