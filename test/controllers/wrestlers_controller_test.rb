require 'test_helper'

class WrestlersControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  setup do
     @tournament = Tournament.find(1)
    # @tournament.generateMatchups
     @school = @tournament.schools.first
     @wrestler = @school.wrestlers.first
  end
 
  def create
    post :create, wrestler: {name: 'Testaasdf', weight_id: 1, school_id: 1}
  end

  def new
    get :new, school: 1
  end

  def post_update
    patch :update, id: @wrestler.id, wrestler: {name: @wrestler.name, weight_id: 1, school_id: 1}
  end

  def destroy
    delete :destroy, id: @wrestler.id
  end

  def get_edit
    get :edit, id: @wrestler.id
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

  test "logged in tournament owner should get edit wrestler page" do
    sign_in_owner
    get_edit
    success
  end
  
  test "logged in tournament delegate should get edit wrestler page" do
    sign_in_tournament_delegate
    get_edit
    success
  end
  
  test "logged in school delegate should get edit wrestler page" do
    sign_in_school_delegate
    get_edit
    success
  end

  test "logged in user should not get edit wrestler page if not owner" do
    sign_in_non_owner
    get_edit
    redirect
  end

  test "non logged in user should not get edit wrestler page" do
    get_edit
    redirect
  end

  test "non logged in user should get post update wrestler" do
    post_update
    redirect
  end 

  test "logged in user should not post update wrestler if not owner" do
    sign_in_non_owner
    post_update
    redirect
  end 

  test "logged in tournament owner should post update wrestler" do
    sign_in_owner
    post_update
    assert_redirected_to school_path(@school.id) 
  end
  
  test "logged in tournament delegate should post update wrestler" do
    sign_in_tournament_delegate
    post_update
    assert_redirected_to school_path(@school.id) 
  end
  
  test "logged in school delegate should post update wrestler" do
    sign_in_school_delegate
    post_update
    assert_redirected_to school_path(@school.id) 
  end

  test "logged in tournament owner can create a new wrestler" do
    sign_in_owner
    new
    success 
    create
    assert_redirected_to school_path(@school.id) 
  end
  
  test "logged in tournament delegate can create a new wrestler" do
    sign_in_tournament_delegate
    new
    success 
    create
    assert_redirected_to school_path(@school.id) 
  end
  
  test "logged in school delegate can create a new wrestler" do
    sign_in_school_delegate
    new
    success 
    create
    assert_redirected_to school_path(@school.id) 
  end

  test "logged in user not tournament owner cannot create a wrestler" do
    sign_in_non_owner
    new
    redirect
    create
    redirect
  end

  test "logged in tournament owner can destroy a wrestler" do
    sign_in_owner
    destroy
    assert_redirected_to school_path(@school.id)
  end
  
  test "logged in tournament delegate can destroy a wrestler" do
    sign_in_tournament_delegate
    destroy
    assert_redirected_to school_path(@school.id)
  end
  
  test "logged in school delegate can destroy a wrestler" do
    sign_in_school_delegate
    destroy
    assert_redirected_to school_path(@school.id)
  end

  test "logged in user not tournament owner cannot destroy wrestler" do
    sign_in_non_owner
    destroy
    redirect
  end

  test "view wrestler" do
    get :show, id: @wrestler.id
    success
  end


end
