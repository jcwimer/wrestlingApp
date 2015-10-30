require 'test_helper'

class SchoolsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  setup do
     @tournament = Tournament.find(1)
     @tournament.generateMatchups
     @school = @tournament.schools.first
  end
 
  def create
    post :create, school: {name: 'Testaasdf', tournament_id: 1}
  end

  def new
    get :new, tournament: @tournament.id
  end

  def post_update
    patch :update, id: @school.id, school: {name: @school.name, tournament_id: @school.tournament_id}
  end

  def destroy
    delete :destroy, id: @school.id
  end

  def get_edit
    get :edit, id: @school.id
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

  test "logged in tournament owner should get edit school page" do
    sign_in_owner
    get_edit
    success
  end

  test "logged in user should not get edit school page if not owner" do
    sign_in_non_owner
    get_edit
    redirect
  end

  test "non logged in user should not get edit school page" do
    get_edit
    redirect
  end

  test "non logged in user should get post update school" do
    post_update
    redirect
  end 

  test "logged in user should not post update school if not owner" do
    sign_in_non_owner
    post_update
    redirect
  end 

  test "logged in tournament owner should post update school" do
    sign_in_owner
    post_update
    assert_redirected_to tournament_path(@school.tournament_id) 
  end

  test "logged in tournament owner can create a new school" do
    sign_in_owner
    new
    success 
    create
    assert_redirected_to tournament_path(@school.tournament_id) 
  end

  test "logged in user not tournament owner cannot create a school" do
    sign_in_non_owner
    new
    redirect
    create
    redirect
  end

  test "logged in tournament owner can destroy a school" do
    sign_in_owner
    destroy
    assert_redirected_to tournament_path(@tournament.id)
  end

  test "logged in user not tournament owner cannot destroy school" do
    sign_in_non_owner
    destroy
    redirect
  end

end
