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

  def get_bracket
    get :up_matches, params: { id: 1 }
  end

  def get_all_brackets
    get :all_brackets, params: { id: 1 }
  end

  def get_up_matches
    get :up_matches, params: { id: 1 }
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
    success
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
  
  # BRACKETS PAGE PERMISSIONS WHEN TOURNAMENT IS NOT PUBLIC
  test "logged in school delegate cannot get bracket page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_school_delegate
    get_bracket
    redirect
  end
  
  test "logged in user cannot get bracket page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_non_owner
    get_bracket
    redirect
  end
  
  test "logged in tournament delegate can get bracket page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_delegate
    get_bracket
    success
  end
  
  test "logged in tournament owner can get bracket page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_owner
    get_bracket
    success
  end
  
  test "non logged in user cannot get bracket page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    get_bracket
    redirect 
  end
  
  # BRACKETS PAGE PERMISSIONS WHEN TOURNAMENT IS PUBLIC
  test "logged in school delegate can get bracket page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    sign_in_school_delegate
    get_bracket
    success
  end
  
  test "logged in user can get bracket page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    sign_in_non_owner
    get_bracket
    success
  end
  
  test "logged in tournament delegate can get bracket page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    sign_in_delegate
    get_bracket
    success
  end
  
  test "logged in tournament owner can get bracket page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    sign_in_owner
    get_bracket
    success
  end
  
  test "non logged in user can get bracket page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    get_bracket
    success 
  end
  # END BRACKETS PAGE PERMISSIONS

  # ALL BRACKETS PAGE PERMISSIONS WHEN TOURNAMENT IS NOT PUBLIC
  test "logged in school delegate cannot get all brackets page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_school_delegate
    get_all_brackets
    redirect
  end
  
  test "logged in user cannot get all brackets page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_non_owner
    get_all_brackets
    redirect
  end
  
  test "logged in tournament delegate can get all brackets page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_delegate
    get_all_brackets
    success
  end
  
  test "logged in tournament owner can get all brackets page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_owner
    get_all_brackets
    success
  end
  
  test "non logged in user cannot get all brackets page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    get_all_brackets
    redirect 
  end
  
  # ALL BRACKETS PAGE PERMISSIONS WHEN TOURNAMENT IS PUBLIC
  test "logged in school delegate can get all brackets page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    sign_in_school_delegate
    get_all_brackets
    success
  end
  
  test "logged in user can get all brackets page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    sign_in_non_owner
    get_all_brackets
    success
  end
  
  test "logged in tournament delegate can get all brackets page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    sign_in_delegate
    get_all_brackets
    success
  end
  
  test "logged in tournament owner can get all brackets page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    sign_in_owner
    get_all_brackets
    success
  end
  
  test "non logged in user can get all brackets page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    get_all_brackets
    success 
  end
  # END ALL BRACKETS PAGE PERMISSIONS

  # UP MATCHES PAGE PERMISSIONS WHEN TOURNAMENT IS NOT PUBLIC
  test "logged in school delegate cannot get up matches page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_school_delegate
    get_up_matches
    redirect
  end
  
  test "logged in user cannot get up matches page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_non_owner
    get_up_matches
    redirect
  end
  
  test "logged in tournament delegate can get up matches page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_delegate
    get_up_matches
    success
  end
  
  test "logged in tournament owner can get up matches page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_owner
    get_up_matches
    success
  end
  
  test "non logged in user cannot get up matches page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    get_up_matches
    redirect 
  end
  
  # UP MATCHES PAGE PERMISSIONS WHEN TOURNAMENT IS PUBLIC
  test "logged in school delegate can get up matches page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    sign_in_school_delegate
    get_up_matches
    success
  end
  
  test "logged in user can get up matches page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    sign_in_non_owner
    get_up_matches
    success
  end
  
  test "logged in tournament delegate can get up matches page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    sign_in_delegate
    get_up_matches
    success
  end
  
  test "logged in tournament owner can get up matches page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    sign_in_owner
    get_up_matches
    success
  end
  
  test "non logged in user can get up matches page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    get_up_matches
    success 
  end
  # END UP MATCHES PAGE PERMISSIONS

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
    success
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

  test 'logged in non owner should not get all matches page' do
    sign_in_non_owner
    get :matches, params: { id: 1 }
    redirect
  end

  test 'logged in owner should get all matches page' do
    sign_in_owner
    get :matches, params: { id: 1 } 
    success
  end

  test "logged in tournament owner can calculate team scores" do
    sign_in_owner
    post :calculate_team_scores, params: { id: 1 }
    assert_redirected_to "/tournaments/#{@tournament.id}"
  end

  test "logged in tournament delegate can calculate team scores" do
    sign_in_delegate
    post :calculate_team_scores, params: { id: 1 }
    assert_redirected_to "/tournaments/#{@tournament.id}"
  end

  test "logged in non tournament owner cannot calculate team scores" do
    sign_in_non_owner
    post :calculate_team_scores, params: { id: 1 }
    redirect
  end
  
  test "logged in school delegate cannot calculate team scores" do
    sign_in_school_delegate
    post :calculate_team_scores, params: { id: 1 }
    redirect
  end

  test "only owner can set user_id when creating a new tournament" do
    # Sign in as owner and create a new tournament
    sign_in_owner
    post :create, params: { tournament: { name: 'New Tournament', address: '123 Main St', director: 'Director', director_email: 'director@example.com', date: '2024-01-01', tournament_type: 'Pool to bracket', is_public: false } }
    new_tournament = Tournament.last
    assert_equal users(:one).id, new_tournament.user_id, "The owner should be assigned as the user_id on creation"
  
    # Sign in as non-owner and try to update the tournament without changing user_id
    sign_in_non_owner
    patch :update, params: { id: new_tournament.id, tournament: { name: 'Updated Tournament', is_public: true } }
    updated_tournament = Tournament.find(new_tournament.id)
    assert_equal users(:one).id, updated_tournament.user_id, "The user_id should not change when the tournament is edited by a non-owner"
  end
end
