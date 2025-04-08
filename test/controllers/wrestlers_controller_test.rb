require 'test_helper'

class WrestlersControllerTest < ActionController::TestCase
  # Remove Devise helpers since we're no longer using Devise
  # include Devise::Test::ControllerHelpers

  setup do
     @tournament = Tournament.find(1)
     @tournament.update(is_public: true)
     @school = @tournament.schools.first
     @school.update(permission_key: SecureRandom.uuid)
     @wrestler = @school.wrestlers.first
  end
 
  def create
    post :create, params: { wrestler: {name: 'Testaasdf', weight_id: 1, school_id: 1} }
  end

  def new
    get :new, params: { school: 1 }
  end

  def post_update
    patch :update, params: { id: @wrestler.id, wrestler: {name: @wrestler.name, weight_id: 1, school_id: 1} }
  end

  def destroy
    delete :destroy, params: { id: @wrestler.id }
  end

  def get_edit
    get :edit, params: { id: @wrestler.id }
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

  # View wrestler based on tournament.is_public

  test "a non logged in user can view wrestler when tournament is_public is true" do
    get :show, params: { id: @wrestler.id }
    success
  end

  test "a non logged in user cannot view wrestler when tournament is_public is false" do
    @tournament.update(is_public: false)
    get :show, params: { id: @wrestler.id }
    redirect
  end

  test "a logged in user non tournament owner cannot view wrestler when tournament is_public is false" do
    @tournament.update(is_public: false)
    sign_in_non_owner
    get :show, params: { id: @wrestler.id }
    redirect
  end

  test "a logged in user tournament owner can view wrestler when tournament is_public is false" do
    @tournament.update(is_public: false)
    sign_in_owner
    get :show, params: { id: @wrestler.id }
    success
  end

  test "a logged in user school delgate can view wrestler when tournament is_public is false" do
    @tournament.update(is_public: false)
    sign_in_school_delegate
    get :show, params: { id: @wrestler.id }
    success
  end

  test "a logged in user tournament delgate can view wrestler when tournament is_public is false" do
    @tournament.update(is_public: false)
    sign_in_tournament_delegate
    get :show, params: { id: @wrestler.id }
    success
  end

  # school permission key tests

  test "a non logged in user with VALID school permission key can view wrestler when tournament is_public is false" do
    valid_key = @school.permission_key
    @tournament.update(is_public: false)
    get :show, params: { id: @wrestler.id, school_permission_key: valid_key }
    success
  end

  test "a non logged in user with INVALID school permission key cannot view wrestler when tournament is_public is false" do
    @tournament.update(is_public: false)
    get :show, params: { id: @wrestler.id, school_permission_key: "INVALID-KEY" }
    redirect
  end

  test "non logged in user with VALID key can get edit wrestler page" do
    valid_key = @school.permission_key
    get :edit, params: { id: @wrestler.id, school_permission_key: valid_key }
    success
  end

  test "non logged in user with INVALID key cannot get edit wrestler page" do
    get :edit, params: { id: @wrestler.id, school_permission_key: "INVALID-KEY" }
    redirect
  end

  test "non logged in user with VALID key can post update wrestler" do
    valid_key = @school.permission_key
    # The form includes school_permission_key as part of wrestler_params
    patch :update, params: { id: @wrestler.id, wrestler: { name: "New Name", school_id: @school.id, school_permission_key: valid_key } }
    assert_redirected_to school_path(@school.id, school_permission_key: valid_key)
  end

  test "non logged in user with INVALID key cannot post update wrestler" do
    patch :update, params: { id: @wrestler.id, wrestler: { name: "New Name", school_id: @school.id }, school_permission_key: "INVALID-KEY" }
    redirect
  end

  test "non logged in user with VALID key can create a new wrestler" do
    valid_key = @school.permission_key

    get :new, params: { school: @school.id, school_permission_key: valid_key }
    success
    # The form includes school_permission_key as part of wrestler_params
    post :create, params: { wrestler: { name: "Test from Key", weight_id: 1, school_id: @school.id, school_permission_key: valid_key }}
    assert_redirected_to school_path(@school.id, school_permission_key: valid_key)
  end

  test "non logged in user with INVALID key cannot create a new wrestler" do
    get :new, params: { school: @school.id, school_permission_key: "INVALID-KEY" }
    redirect
    post :create, params: { wrestler: { name: "Test from Key", weight_id: 1, school_id: @school.id }, school_permission_key: "INVALID-KEY" }
    redirect
  end

  test "non logged in user with VALID key can destroy a wrestler" do
    valid_key = @school.permission_key
    delete :destroy, params: { id: @wrestler.id, school_permission_key: valid_key }
    assert_redirected_to school_path(@school.id, school_permission_key: valid_key)
  end

  test "non logged in user with INVALID key cannot destroy a wrestler" do
    delete :destroy, params: { id: @wrestler.id, school_permission_key: "INVALID-KEY" }
    redirect
  end

  test "non logged in user with VALID key can view a wrestler" do
    valid_key = @school.permission_key
    get :show, params: { id: @wrestler.id, school_permission_key: valid_key }
    success
  end

  test "non logged in user with INVALID key cannot view a wrestler" do
    @tournament.update(is_public: false)
    get :show, params: { id: @wrestler.id, school_permission_key: "INVALID-KEY" }
    redirect
  end

  test "show page with valid school_permission_key includes it in 'Back to School' link" do
    valid_key = @school.permission_key
    get :show, params: { id: @wrestler.id, school_permission_key: valid_key }
    success

    # The link is typically: /schools/:id?school_permission_key=valid_key
    # 'Back to Central Crossing' or similar text
    assert_select "a[href=?]", school_path(@school, school_permission_key: valid_key), text: /Back to/
  end

  test "show page with NO key does not include it in 'Back to School' link" do
    get :show, params: { id: @wrestler.id }
    success

    assert_select "a[href=?]", school_path(@school), text: /Back to/
  end
end
