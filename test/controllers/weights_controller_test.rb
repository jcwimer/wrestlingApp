require 'test_helper'

class WeightsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
     @tournament = Tournament.find(1)
    # @tournament.generateMatchups
     @weight = @tournament.weights.first
     @wrestler = @weight.wrestlers.first
  end
 
  def create
    post :create, params: { weight: {max: 60000, tournament_id: 1} }
  end

  def new
    get :new, params: { tournament: @tournament.id }
  end

  def post_update
    patch :update, params: { id: @weight.id, weight: {max: @weight.max, tournament_id: @weight.tournament_id} }
  end

  def destroy
    delete :destroy, params: { id: @weight.id }
  end

  def get_edit
    get :edit, params: { id: @weight.id }
  end

  def get_show
    get :show, params: { id: @weight.id }
  end

  def get_pool_order
    post :pool_order, params: {pool_to_order: 1, id: @weight.id}
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
    assert_redirected_to '/static_pages/not_allowed'
  end

  def delete_wrestler_from_weight_show_page
    get :show, params: { id: @weight.id }
    old_controller = @controller
    @controller = WrestlersController.new
    delete :destroy, params: { id: @wrestler.id }
    @controller = old_controller
  end

  test "redirect to weight show when deleting a wrestler from weight show" do
    sign_in_owner
    delete_wrestler_from_weight_show_page
    assert_redirected_to "/weights/#{@weight.id}"
  end

  test "logged in tournament owner should get edit weight page" do
    sign_in_owner
    get_edit
    success
  end
  
  test "logged in tournament delegate should get edit weight page" do
    sign_in_tournament_delegate
    get_edit
    success
  end

  test "logged in user should not get edit weight page if not owner" do
    sign_in_non_owner
    get_edit
    redirect
  end
  
  test "logged school delegate should not get edit weight page if not owner" do
    sign_in_school_delegate
    get_edit
    redirect
  end

  test "non logged in user should not get edit weight page" do
    get_edit
    redirect
  end

  test "non logged in user should get post update weight" do
    post_update
    redirect
  end 

  test "logged in user should not post update weight if not owner" do
    sign_in_non_owner
    post_update
    redirect
  end 
  
  test "logged school delegate should not post update weight if not owner" do
    sign_in_school_delegate
    post_update
    redirect
  end 

  test "logged in tournament owner should post update weight" do
    sign_in_owner
    post_update
    assert_redirected_to tournament_path(@weight.tournament_id) 
  end
  
  test "logged in tournament delegate should post update weight" do
    sign_in_tournament_delegate
    post_update
    assert_redirected_to tournament_path(@weight.tournament_id) 
  end

  test "logged in tournament owner can create a new weight" do
    sign_in_owner
    new
    success 
    create
    assert_redirected_to tournament_path(@weight.tournament_id) 
  end
  
  test "logged in tournament delegate can create a new weight" do
    sign_in_tournament_delegate
    new
    success 
    create
    assert_redirected_to tournament_path(@weight.tournament_id) 
  end

  test "logged in user not tournament owner cannot create a weight" do
    sign_in_non_owner
    new
    redirect
    create
    redirect
  end
  
  test "logged school delegate not tournament owner cannot create a weight" do
    sign_in_school_delegate
    new
    redirect
    create
    redirect
  end

  test "logged in tournament owner can destroy a weight" do
    sign_in_owner
    destroy
    assert_redirected_to tournament_path(@tournament.id)
  end
  
  test "logged in tournament delegate can destroy a weight" do
    sign_in_tournament_delegate
    destroy
    assert_redirected_to tournament_path(@tournament.id)
  end

  test "logged in user not tournament owner cannot destroy weight" do
    sign_in_non_owner
    destroy
    redirect
  end
  
  test "logged school delegate not tournament owner cannot destroy weight" do
    sign_in_school_delegate
    destroy
    redirect
  end

  test "logged in tournament owner can calculate a pool" do
    sign_in_owner
    get_pool_order
    assert_redirected_to tournament_path(@tournament.id)
  end
  
  test "logged in tournament delegate can calculate a pool" do
    sign_in_tournament_delegate
    get_pool_order
    assert_redirected_to tournament_path(@tournament.id)
  end

  test "logged in user not tournament owner cannot calculate a pool" do
    sign_in_non_owner
    get_pool_order
    redirect
  end
  
  test "logged school delegate not tournament owner cannot calculate a pool" do
    sign_in_school_delegate
    get_pool_order
    redirect
  end

  # SHOW PAGE PERMISSIONS WHEN TOURNAMENT IS NOT PUBLIC
  test "logged in school delegate cannot get show page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_school_delegate
    get_show
    redirect
  end

  test "logged in user cannot get show page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_non_owner
    get_show
    redirect
  end

  test "logged in tournament delegate can get show page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_tournament_delegate
    get_show
    success
  end

  test "logged in tournament owner can get show page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_owner
    get_show
    success
  end

  test "non logged in user cannot get show page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    get_show
    redirect 
  end

  # SHOW PAGE PERMISSIONS WHEN TOURNAMENT IS PUBLIC
  test "logged in school delegate can get show page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    sign_in_school_delegate
    get_show
    success
  end

  test "logged in user can get show page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    sign_in_non_owner
    get_show
    success
  end

  test "logged in tournament delegate can get show page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    sign_in_tournament_delegate
    get_show
    success
  end

  test "logged in tournament owner can get show page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    sign_in_owner
    get_show
    success
  end

  test "non logged in user can get show page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    get_show
    success 
  end
  # END SHOW PAGE PERMISSIONS

  test "view wegiht" do
    get :show, params: { id: 1 }
    success
  end

end
