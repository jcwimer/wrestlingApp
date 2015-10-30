require 'test_helper'

class MatsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  setup do
     @tournament = Tournament.find(1)
     @tournament.generateMatchups
     @mat = mats(:one)
  end
 
  def create
    post :create, mat: {name: 'Mat100', tournament_id: 1}
  end

  def new
    get :new, tournament: @tournament.id
  end

  def post_update
    patch :update, id: @mat.id, mat: {name: @mat.name, tournament_id: @mat.tournament_id}
  end

  def destroy
    delete :destroy, id: @mat.id
  end

  def get_edit
    get :edit, id: @mat.id
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

  test "logged in tournament owner should get edit mat page" do
    sign_in_owner
    get_edit
    success
  end

  test "logged in user should not get edit mat page if not owner" do
    sign_in_non_owner
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

  test "logged in tournament owner should post update mat" do
    sign_in_owner
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

  test "logged in user not tournament owner cannot create a mat" do
    sign_in_non_owner
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

  test "logged in user not tournament owner cannot destroy mat" do
    sign_in_non_owner
    destroy
    redirect
  end
end
