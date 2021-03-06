require 'test_helper'

class MatchesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
     @tournament = Tournament.find(1)
    # @tournament.generateMatchups
     @match = Match.where("tournament_id = ? and mat_id = ?",1,1).first
  end
 
  def post_update
    patch :update, params: { id: @match.id, match: {tournament_id: 1, mat_id: 1} }
  end

  def post_update_from_match_edit
    get :edit, params: { id: @match.id }
    patch :update, params: { id: @match.id, match: {tournament_id: 1, mat_id: 1} }
  end
 
  def get_edit
    get :edit, params: { id: @match.id }
  end

  def post_update_from_match_stat
    get :stat, params: { id: @match.id }
    patch :update, params: { id: @match.id, match: {tournament_id: 1, mat_id: 1} }
  end
 
  def get_stat
    get :stat, params: { id: @match.id }
  end
  
  def sign_in_owner
    sign_in users(:one)
  end

  def sign_in_non_owner
    sign_in users(:two)
  end
  
  def sign_in_tournament_delegate
    sign_in users(:three)
  end
  
  def sign_in_school_delegate
    sign_in users(:four)
  end

  def success
    assert_response :success
  end

  def redirect
    assert_response :redirect
  end

   test "the truth" do
     assert true
   end

  test "logged in tournament owner should get edit match page" do
    sign_in_owner
    get_edit
    success
  end

  test "logged in user should not get edit match page if not owner" do
    sign_in_non_owner
    get_edit
    redirect
  end
  
  test "logged school delegate should not get edit match page if not owner" do
    sign_in_school_delegate
    get_edit
    redirect
  end

  test "non logged in user should not get edit match page" do
    get_edit
    redirect
  end

  test "logged school delegate should not get stat match page if not owner" do
    sign_in_school_delegate
    get_stat
    redirect
  end

  test "non logged in user should not get stat match page" do
    get_stat
    redirect
  end

  test "non logged in user should get post update match" do
    post_update
    assert_redirected_to '/static_pages/not_allowed' 
  end 

  test "logged in user should not post update match if not owner" do
    sign_in_non_owner
    post_update
    assert_redirected_to '/static_pages/not_allowed' 
  end 
  
  test "logged school delegate should not post update match if not owner" do
    sign_in_school_delegate
    post_update
    assert_redirected_to '/static_pages/not_allowed' 
  end

  test "logged in tournament delegate should get edit match page" do
    sign_in_tournament_delegate
    get_edit
    success
  end

  test "logged in tournament delegate should get stat match page" do
    sign_in_tournament_delegate
    get_stat
    success
  end
  
  test "logged in tournament delegate should post update match" do
    sign_in_tournament_delegate
    post_update
    assert_redirected_to tournament_path(@tournament.id) 
  end

  test "should redirect to all matches when posting a match update from match edit" do
    sign_in_owner
    post_update_from_match_edit
    assert_redirected_to "/tournaments/#{@tournament.id}/matches" 
  end

  test "should redirect to all matches when posting a match update from match stat" do
    sign_in_owner
    post_update_from_match_stat
    assert_redirected_to "/tournaments/#{@tournament.id}/matches" 
  end
end
