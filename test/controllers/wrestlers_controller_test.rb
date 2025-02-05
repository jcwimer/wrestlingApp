require 'test_helper'

class WrestlersControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @tournament = Tournament.find(1)
    @school = @tournament.schools.first
    @wrestler = @school.wrestlers.first
    @school.update(permission_key: SecureRandom.uuid)
    @school_permission_key = @school.permission_key
  end

  def create(extra_params = {})
    post :create, params: { wrestler: { name: 'Test Wrestler', weight_id: 1, school_id: @school.id, school_permission_key: @school_permission_key } }.merge(extra_params)
  end

  def new(extra_params = {})
    get :new, params: { school: @school.id, school_permission_key: extra_params[:school_permission_key] || @school_permission_key }
  end

  def post_update(extra_params = {})
    patch :update, params: { id: @wrestler.id, wrestler: { name: @wrestler.name, weight_id: 1, school_id: @school.id, school_permission_key: extra_params[:school_permission_key] || @school_permission_key } }
  end

  def destroy(extra_params = {})
    delete :destroy, params: { id: @wrestler.id, school_permission_key: extra_params[:school_permission_key] || @school_permission_key }
  end

  def get_edit(extra_params = {})
    get :edit, params: { id: @wrestler.id, school_permission_key: extra_params[:school_permission_key] || @school_permission_key }
  end

  def sign_in_owner; sign_in users(:one); end
  def sign_in_non_owner; sign_in users(:two); end
  def sign_in_tournament_delegate; sign_in users(:three); end
  def sign_in_school_delegate; sign_in users(:four); end

  def success
    assert_response :success
  end

  def redirect_to_not_allowed
    assert_redirected_to '/static_pages/not_allowed'
  end

  # Existing permission tests...

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
    redirect_to_not_allowed
  end

  test "non logged in user should not get edit wrestler page" do
    get_edit
    redirect_to_not_allowed
  end

  test "logged in tournament owner should post update wrestler" do
    sign_in_owner
    post_update
    assert_redirected_to school_path(@school.id, school_permission_key: @school_permission_key)
  end

  test "logged in tournament delegate should post update wrestler" do
    sign_in_tournament_delegate
    post_update
    assert_redirected_to school_path(@school.id, school_permission_key: @school_permission_key)
  end

  test "logged in school delegate should post update wrestler" do
    sign_in_school_delegate
    post_update
    assert_redirected_to school_path(@school.id, school_permission_key: @school_permission_key)
  end

  test "logged in tournament owner can create a new wrestler" do
    sign_in_owner
    new
    success
    create
    assert_redirected_to school_path(@school.id, school_permission_key: @school_permission_key)
  end

  test "logged in tournament delegate can create a new wrestler" do
    sign_in_tournament_delegate
    new
    success
    create
    assert_redirected_to school_path(@school.id, school_permission_key: @school_permission_key)
  end

  test "logged in school delegate can create a new wrestler" do
    sign_in_school_delegate
    new
    success
    create
    assert_redirected_to school_path(@school.id, school_permission_key: @school_permission_key)
  end

  test "logged in user not tournament owner cannot create a wrestler" do
    sign_in_non_owner
    new
    redirect_to_not_allowed
    create
    redirect_to_not_allowed
  end

  test "logged in tournament owner can destroy a wrestler" do
    sign_in_owner
    destroy
    assert_redirected_to school_path(@school.id, school_permission_key: @school_permission_key)
  end

  test "logged in tournament delegate can destroy a wrestler" do
    sign_in_tournament_delegate
    destroy
    assert_redirected_to school_path(@school.id, school_permission_key: @school_permission_key)
  end

  test "logged in school delegate can destroy a wrestler" do
    sign_in_school_delegate
    destroy
    assert_redirected_to school_path(@school.id, school_permission_key: @school_permission_key)
  end

  test "logged in user not tournament owner cannot destroy wrestler" do
    sign_in_non_owner
    destroy
    redirect_to_not_allowed
  end

  test "view wrestler" do
    get :show, params: { id: @wrestler.id }
    success
  end

  # NEW TESTS: Verify that redirects preserve the school_permission_key

  test "redirect back to school show preserves school_permission_key on create" do
    sign_in_school_delegate
    create(school_permission_key: @school_permission_key)
    assert_redirected_to school_path(@school.id, school_permission_key: @school_permission_key)
  end

  test "redirect back to school show preserves school_permission_key on update" do
    sign_in_school_delegate
    post_update(school_permission_key: @school_permission_key)
    assert_redirected_to school_path(@school.id, school_permission_key: @school_permission_key)
  end

  test "redirect back to school show preserves school_permission_key on delete" do
    sign_in_school_delegate
    destroy(school_permission_key: @school_permission_key)
    assert_redirected_to school_path(@school.id, school_permission_key: @school_permission_key)
  end

  # NEW TESTS: Verify that the forms include the hidden field for school_permission_key

  test "wrestler form includes school_permission_key hidden field when used" do
    sign_in_school_delegate
    new(school_permission_key: @school_permission_key)
    # Look for the hidden field rendered by f.hidden_field :school_permission_key
    assert_select "input[name=?][value=?]", "wrestler[school_permission_key]", @school_permission_key
  end

  test "edit wrestler form includes school_permission_key hidden field when used" do
    sign_in_school_delegate
    get_edit(school_permission_key: @school_permission_key)
    assert_select "input[name=?][value=?]", "wrestler[school_permission_key]", @school_permission_key
  end

  # NEW TESTS: Verify that wrestler links include the school_permission_key when used

  test "wrestler links include school_permission_key when used" do
    sign_in_school_delegate
    get :show, params: { id: @school.id, school_permission_key: @school_permission_key }
    # Check new wrestler link
    assert_select "a[href=?]", new_wrestler_path(school: @school.id, school_permission_key: @school_permission_key), text: /New Wrestler/i

    @school.wrestlers.each do |wrestler|
      assert_select "a[href=?]", edit_wrestler_path(wrestler, school_permission_key: @school_permission_key)
      assert_select "a[href=?][data-method=delete]", wrestler_path(wrestler, school_permission_key: @school_permission_key)
    end
  end

  test "wrestler links do not include school_permission_key when not used" do
    sign_in_school_delegate
    get :show, params: { id: @school.id }
    assert_select "a[href=?]", new_wrestler_path(school: @school.id), text: /New Wrestler/i

    @school.wrestlers.each do |wrestler|
      assert_select "a[href=?]", edit_wrestler_path(wrestler), count: 1
      assert_select "a[href=?][data-method=delete]", wrestler_path(wrestler), count: 1
    end
  end
end
