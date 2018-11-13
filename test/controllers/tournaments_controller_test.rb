require 'test_helper'

class TournamentsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
     @tournament = Tournament.find(1)
    # @tournament.generateMatchups
     @school = @tournament.schools.first
     @wrestlers = @tournament.weights.first.wrestlers
     @adjust = Teampointadjust.find(1)
  end

  def post_update
    patch :update, params: { id: 1, tournament: {name: @tournament.name} }
  end
 
  def get_edit
    get :edit, params: { id: 1 }
  end

  def sign_in_owner
    sign_in users(:one)
  end

  def sign_in_non_owner
    sign_in users(:two)
  end
  
  def sign_in_delegate
    sign_in users(:three)
  end
  
  def sign_in_school_delegate
    sign_in users(:four)
  end

  def success
    assert_response :success
  end

  def redirect
    assert_redirected_to '/static_pages/not_allowed'
  end

  def destroy
    delete :destroy, params: { id: 1 }
  end

  def no_matches
    assert_redirected_to "/tournaments/#{@tournament.id}/no_matches"
  end
  
  def wipe
    @tournament.destroy_all_matches
  end

  test "logged in tournament owner can generate matches" do
    sign_in_owner
    get :generate_matches, params: { id: 1 }
    success
  end

  test "logged in non tournament owner cannot generate matches" do
    sign_in_non_owner
    get :generate_matches, params: { id: 1 }
    redirect
  end
  
  test "logged in school delegate cannot generate matches" do
    sign_in_school_delegate
    get :generate_matches, params: { id: 1 }
    redirect
  end

  test "logged in tournament owner can create custom weights" do
    sign_in_owner
    get :create_custom_weights, params: { id: 1, customValue: 'hs' } 
    assert_redirected_to '/tournaments/1'
  end

  test "logged in non tournament owner cannot create custom weights" do
    sign_in_non_owner
    get :create_custom_weights, params: { id: 1, customValue: 'hs' }
    redirect
  end
  
  test "logged in school delegate cannot create custom weights" do
    sign_in_school_delegate
    get :create_custom_weights, params: { id: 1, customValue: 'hs' } 
    redirect
  end


  test "logged in tournament owner can access weigh_ins" do
    sign_in_owner
    get :weigh_in, params: { id: 1 }
    success
  end

  test "logged in non tournament owner cannot access weigh_ins" do
    sign_in_non_owner
    get :weigh_in, params: { id: 1 }
    redirect    
  end
  
  test "logged in school delegate cannot access weigh_ins" do
    sign_in_school_delegate
    get :weigh_in, params: { id: 1 }
    redirect    
  end

  test "logged in tournament owner can access weigh_in_weight" do
    sign_in_owner
    get :weigh_in, params: { id: 1, weight: 1 }
    success
  end

  test "logged in non tournament owner cannot access weigh_in_weight" do
    sign_in_non_owner
    get :weigh_in_weight, params: { id: 1, weight: 1 }
    redirect    
  end
  
  test "logged in school delegate cannot access weigh_in_weight" do
    sign_in_school_delegate
    get :weigh_in_weight, params: { id: 1, weight: 1 }
    redirect    
  end
  
  test "logged in tournament owner can access post weigh_in_weight" do
    sign_in_owner
    post :weigh_in, params: { id: 1, weight: 1, wrestler: @wrestlers }
  end

  test "logged in non tournament owner cannot access post weigh_in_weight" do
    sign_in_non_owner
    post :weigh_in_weight, params: { id: 1, weight: 1, wrestler: @wrestlers }
    redirect    
  end
  
  test "logged in school delegate cannot access post weigh_in_weight" do
    sign_in_school_delegate
    post :weigh_in_weight, params: { id: 1, weight: 1, wrestler: @wrestlers }
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
  
  test "logged in school delegate should not get edit tournament page if not owner" do
    sign_in_school_delegate
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
  
  test "logged in school delegate should not post update tournament if not owner" do
    sign_in_school_delegate
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
  
  test "logged in school delegate not tournament owner cannot destroy tournament" do
    sign_in_school_delegate
    destroy
    redirect
  end
  

#TESTS THAT NEED MATCHES PUT ABOVE THIS
  test "redirect up_matches if no matches" do
    sign_in_owner
    wipe
    get :up_matches, params: { id: 1 }
    no_matches
  end
  
  test "redirect bracket if no matches" do
    sign_in_owner
    wipe
    get :bracket, params: { id: 1, weight: 1 }
    no_matches
  end
  
  test "logged in tournament delegate can generate matches" do
    sign_in_delegate
    get :generate_matches, params: { id: 1 }
    success
  end

  test "logged in tournament delegate can create custom weights" do
    sign_in_delegate
    get :create_custom_weights, params: { id: 1, customValue: 'hs' }
    assert_redirected_to '/tournaments/1'
  end

  test "logged in tournament delegate can access weigh_ins" do
    sign_in_delegate
    get :weigh_in, params: { id: 1 }
    success
  end

  test "logged in tournament delegate can access weigh_in_weight" do
    sign_in_delegate
    get :weigh_in, params: { id: 1, weight: 1 }
    success
  end
  
  test "logged in tournament delegate should get edit tournament page" do
    sign_in_delegate
    get_edit
    success
  end
  
  test "logged in tournament delegate can access post weigh_in_weight" do
    sign_in_delegate
    post :weigh_in, params: { id: 1, weight: 1, wrestler: @wrestlers }
  end
  
  test "logged in tournament delegate should post update tournament" do
    sign_in_delegate
    post_update
    assert_redirected_to tournament_path(1) 
  end


  test "logged in tournament delegate cannot destroy a tournament" do
    sign_in_delegate
    destroy
    redirect
  end
  
  test 'logged in tournament owner can delegate a user' do
    sign_in_owner
    get :delegate, params: { id: 1 }
    success
  end
  
  test 'logged in tournament delegate cannot delegate a user' do
    sign_in_delegate
    get :delegate, params: { id: 1 }
    redirect
  end
  
  test 'logged in tournament owner can delegate a school user' do
    sign_in_owner
    get :school_delegate, params: { id: 1 }
    success
  end
  
  test 'logged in tournament delegate can delegate a school user' do
    sign_in_delegate
    get :school_delegate, params: { id: 1 }
    success
  end
  
  test 'logged in tournament owner can delete a school delegate' do
    sign_in_owner
    patch :remove_school_delegate, params: { id: 1, delegate: SchoolDelegate.find(1) }
    assert_redirected_to "/tournaments/#{@tournament.id}/school_delegate"
  end
  
  test 'logged in tournament delegate can delete a school delegate' do
    sign_in_delegate
    patch :remove_school_delegate, params: { id: 1, delegate: SchoolDelegate.find(1) }
    assert_redirected_to "/tournaments/#{@tournament.id}/school_delegate"
  end
  
  test 'logged in tournament owner can delete a delegate' do
    sign_in_owner
    patch :remove_delegate, params: { id: 1, delegate: TournamentDelegate.find(1) }
    assert_redirected_to "/tournaments/#{@tournament.id}/delegate"
  end
  
  test 'logged in tournament delegate cannot delete a delegate' do
    sign_in_delegate
    patch :remove_delegate, params: { id: 1, delegate: TournamentDelegate.find(1) }
    redirect
  end
  
  
  
  
   test 'logged in tournament delegate can adjust team points' do
    sign_in_delegate
    get :teampointadjust, params: { id: 1 }
    success
  end
  
  test 'logged in tournament owner can adjust team points' do
    sign_in_owner
    get :teampointadjust, params: { id: 1 }
    success
  end
  
  test 'logged in tournament delegate cannot adjust team points' do
    sign_in_school_delegate
    get :teampointadjust, params: { id: 1 }
    redirect
  end
  
  test 'logged in tournament owner can delete team point adjust' do
    sign_in_owner
    post :remove_teampointadjust, params: { id: 1, teampointadjust: Teampointadjust.find(1) }
    assert_redirected_to "/tournaments/#{@tournament.id}/teampointadjust"
  end
  
  test 'logged in tournament delegate can team point adjust' do
    sign_in_delegate
    post :remove_teampointadjust, params: { id: 1, teampointadjust: Teampointadjust.find(1) }
    assert_redirected_to "/tournaments/#{@tournament.id}/teampointadjust"
  end
  
  test 'logged in school delegate cannot delete team point adjust' do
    sign_in_school_delegate
    post :remove_teampointadjust, params: { id: 1, teampointadjust: Teampointadjust.find(1) }
    redirect
  end


end
