require 'test_helper'

class MatsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
     @tournament = Tournament.find(1)
    # @tournament.generateMatchups
     @mat = mats(:one)
  end
 
  def create
    post :create, params: { mat: {name: 'Mat100', tournament_id: 1} }
  end

  def new
    get :new, params: { tournament: @tournament.id }
  end
  
  def show
    get :show,  params: { id: 1 }
  end

  def post_update
    patch :update, params: { id: @mat.id, mat: {name: @mat.name, tournament_id: @mat.tournament_id} }
  end

  def destroy
    delete :destroy, params: { id: @mat.id }
  end

  def get_edit
    get :edit, params: { id: @mat.id }
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
  
  def no_matches
    assert_redirected_to "/tournaments/#{@tournament.id}/no_matches"
  end
  
  def wipe
    @tournament.destroy_all_matches
  end

  test "logged in tournament owner should get edit mat page" do
    sign_in_owner
    get_edit
    success
  end
  
  test "logged in tournament delegate should get edit mat page" do
    sign_in_tournament_delegate
    get_edit
    success
  end

  test "logged in user should not get edit mat page if not owner" do
    sign_in_non_owner
    get_edit
    redirect
  end
  
  test "logged school delegate should not get edit mat page if not owner" do
    sign_in_school_delegate
    get_edit
    redirect
  end

  test "non logged in user should not get edit mat page" do
    get_edit
    redirect
  end

  test "non logged in user should get post update mat" do
    post_update
    redirect
  end 

  test "logged in user should not post update mat if not owner" do
    sign_in_non_owner
    post_update
    redirect
  end 
  
  test "logged school delegate should not post update mat if not owner" do
    sign_in_school_delegate
    post_update
    redirect
  end

  test "logged in tournament owner should post update mat" do
    sign_in_owner
    post_update
    assert_redirected_to tournament_path(@mat.tournament_id) 
  end
  
  test "logged in tournament delegate should post update mat" do
    sign_in_tournament_delegate
    post_update
    assert_redirected_to tournament_path(@mat.tournament_id) 
  end

  test "logged in tournament owner can create a new mat" do
    sign_in_owner
    new
    success 
    create
    assert_redirected_to tournament_path(@mat.tournament_id) 
  end
  
  test "logged in tournament delegate can create a new mat" do
    sign_in_tournament_delegate
    new
    success 
    create
    assert_redirected_to tournament_path(@mat.tournament_id) 
  end

  test "logged in user not tournament owner cannot create a mat" do
    sign_in_non_owner
    new
    redirect
    create
    redirect
  end
  
  test "logged school delegate not tournament owner cannot create a mat" do
    sign_in_school_delegate
    new
    redirect
    create
    redirect
  end

  test "logged in tournament owner can destroy a mat" do
    sign_in_owner
    destroy
    assert_redirected_to tournament_path(@tournament.id)
  end
  
  test "logged in tournament delegate can destroy a mat" do
    sign_in_tournament_delegate
    destroy
    assert_redirected_to tournament_path(@tournament.id)
  end

  test "logged in user not tournament owner cannot destroy mat" do
    sign_in_non_owner
    destroy
    redirect
  end
  
  test "logged school delegate not tournament owner cannot destroy mat" do
    sign_in_school_delegate
    destroy
    redirect
  end
  
  test "logged in user should not get show mat" do
    sign_in_non_owner
    show
    redirect 
  end 
  
  test "logged school delegate should not get show mat" do
    sign_in_school_delegate
    show
    redirect 
  end

  test "logged in tournament owner should get show mat" do
    sign_in_owner
    show
    success
  end
  
  test "logged in tournament delegate should get show mat" do
    sign_in_tournament_delegate
    show
    success
  end


#TESTS THAT NEED MATCHES PUT ABOVE THIS
  test "redirect show if no matches" do
    sign_in_owner
    wipe
    show
    no_matches
  end
end
