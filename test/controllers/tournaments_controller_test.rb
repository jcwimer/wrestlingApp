require 'test_helper'

class TournamentsControllerTest < ActionController::TestCase
include Devise::TestHelpers

  setup do
     @tournament = Tournament.find(1)
     @tournament.generateMatchups
     @school = @tournament.schools.first
     @wrestlers = @tournament.weights.first.wrestlers
  end

  def post_update
    patch :update, id: 1, tournament: {name: @tournament.name}
  end
 
  def get_edit
    get :edit, id: 1
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

  def destroy
    delete :destroy, id: 1
  end

  def no_matches
    assert_redirected_to "/tournaments/#{@tournament.id}/no_matches"
  end
  
  def wipe
    @tournament.destroyAllMatches
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

  test "logged in tournament owner can create custom weights" do
    sign_in_owner
    get :create_custom_weights, id: 1, customValue: 'hs' 
    assert_redirected_to '/tournaments/1'
  end

  test "logged in non tournament owner cannot create custom weights" do
    sign_in_non_owner
    get :create_custom_weights, id: 1, customValue: 'hs' 
    redirect
  end


  test "logged in tournament owner can access weigh_ins" do
    sign_in_owner
    get :weigh_in, id: 1
    success
  end

  test "logged in non tournament owner cannot access weigh_ins" do
    sign_in_non_owner
    get :weigh_in, id: 1
    redirect    
  end

  test "logged in tournament owner can access weigh_in_weight" do
    sign_in_owner
    get :weigh_in, id: 1, weight: 1
    success
  end

  test "logged in non tournament owner cannot access weigh_in_weight" do
    sign_in_non_owner
    get :weigh_in_weight, id: 1, weight: 1
    redirect    
  end
  
  test "logged in tournament owner can access post weigh_in_weight" do
    sign_in_owner
    post :weigh_in, id: 1, weight: 1, wrestler: @wrestlers
  end

  test "logged in non tournament owner cannot access post weigh_in_weight" do
    sign_in_non_owner
    post :weigh_in_weight, id: 1, weight: 1, wrestler: @wrestlers
    redirect    
  end


  test "logged in tournament owner should get edit tournament page" do
    sign_in_owner
    get_edit
    success
  end

  test "logged in user should not get edit tournament page if not owner" do
    sign_in_non_owner
    get_edit
    redirect
  end

  test "non logged in user should not get edit tournament page" do
    get_edit
    redirect
  end

  test "non logged in user should get post update tournament" do
    post_update
    assert_redirected_to '/static_pages/not_allowed' 
  end 

  test "logged in user should not post update tournament if not owner" do
    sign_in_non_owner
    post_update
    assert_redirected_to '/static_pages/not_allowed' 
  end 

  test "logged in tournament owner should post update tournament" do
    sign_in_owner
    post_update
    assert_redirected_to tournament_path(1) 
  end


  test "logged in tournament owner can destroy a tournament" do
    sign_in_owner
    destroy
    assert_redirected_to tournaments_path
  end

  test "logged in user not tournament owner cannot destroy tournament" do
    sign_in_non_owner
    destroy
    redirect
  end
  

#TESTS THAT NEED MATCHES PUT ABOVE THIS
  test "redirect up_matches if no matches" do
    sign_in_owner
    wipe
    get :up_matches, id: 1
    no_matches
  end
  
  test "redirect bracket if no matches" do
    sign_in_owner
    wipe
    get :bracket, id: 1, weight: 1
    no_matches
  end

end
