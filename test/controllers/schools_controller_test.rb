require 'test_helper'

class SchoolsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @tournament = Tournament.find(1)
    # @tournament.generateMatchups
    @school = @tournament.schools.first
    @school.update(permission_key: SecureRandom.uuid) # Generate a valid school_permission_key
    @school_permission_key = @school.permission_key
  end
 
  def create
    post :create, params: { school: {name: 'Testaasdf', tournament_id: 1} }
  end

  def new
    get :new, params: { tournament: @tournament.id }
  end

  def get_show(extra_params = {})
    get :show, params: { id: @school.id }.merge(extra_params)
  end

  def post_update(extra_params = {})
    patch :update, params: { id: @school.id, school: { name: @school.name, tournament_id: @school.tournament_id } }.merge(extra_params)
  end

  def destroy(extra_params = {})
    delete :destroy, params: { id: @school.id }.merge(extra_params)
  end

  def get_edit(extra_params = {})
    get :edit, params: { id: @school.id }.merge(extra_params)
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

  def baums_import
    baums_text = "***** 2019-01-09 13:36:50 *****
Some School
Some Guy
106,,,,,,,,,
113,Guy,Another,9,,,,,5,7
120,Guy2,Another,9,,,,,0,0
126,Guy3,Another,10,,,,5@120,2,2
******* Extra Wrestlers *******
120,Guy4,Another,10,0,3
126,Guy5,Another,9,,"

    post :import_baumspage_roster, params: { id: @school.id, school: { baums_text: baums_text } }
  end

  test "logged in tournament owner should get edit school page" do
    sign_in_owner
    get_edit
    success
  end
  
  test "logged in tournament delegate should get edit school page" do
    sign_in_tournament_delegate
    get_edit
    success
  end
  
  test "logged in school delegate should get edit school page" do
    sign_in_school_delegate
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
  
  test "logged in tournament delegate should post update school" do
    sign_in_tournament_delegate
    post_update
    assert_redirected_to tournament_path(@school.tournament_id) 
  end
  
  test "logged in school delegate should post update school" do
    sign_in_school_delegate
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
  
  test "logged in tournament delegate can create a new school" do
    sign_in_tournament_delegate
    new
    success 
    create
    assert_redirected_to tournament_path(@school.tournament_id) 
  end
  
  test "logged in school delegate cannot create a new school" do
    sign_in_school_delegate
    new
    redirect 
    create
    redirect
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
  
  test "logged in tournament delegate can destroy a school" do
    sign_in_tournament_delegate
    destroy
    assert_redirected_to tournament_path(@tournament.id)
  end
  
  test "logged in school delegate can destroy a school" do
    sign_in_school_delegate
    destroy
    redirect
  end

  test "logged in user not tournament owner cannot destroy school" do
    sign_in_non_owner
    destroy
    redirect
  end
  
  test "view school" do
    get :show, params: { id: 1 }
    success
  end

  test "logged in school delegate can import baumspage roster" do
    sign_in_school_delegate
    baums_import
    assert_redirected_to "/schools/#{@school.id}"
  end

  test "logged in tournament delegate can import baumspage roster" do
    sign_in_tournament_delegate
    baums_import
    assert_redirected_to "/schools/#{@school.id}"
  end

  test "logged in user cannot import baumspage roster" do
    sign_in_non_owner
    baums_import
    redirect
  end

  # SHOW PAGE PERMISSIONS WHEN TOURNAMENT IS NOT PUBLIC
  test "logged in school delegate can get show page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_school_delegate
    get_show
    success
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

  test "non logged in user can get stats page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    get :stats, params: { id: @school.id }
    success 
  end

  test "logged in school delegate can get stats page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_school_delegate
    get :stats, params: { id: @school.id }
    success
  end

  test "logged in tournament owner can get stats page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_owner
    get :stats, params: { id: @school.id }
    success
  end

  test "logged in tournament delegate can get stats page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_tournament_delegate
    get :stats, params: { id: @school.id }
    success
  end

  test "logged in non owner cannot get stats page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_non_owner
    get :stats, params: { id: @school.id }
    redirect
  end

  test "non logged in user cannot get stats page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_non_owner
    get :stats, params: { id: @school.id }
    redirect
  end

  test "stats page without school_permission_key does not include it in 'Back to School' link" do
    get :stats, params: { id: @school.id }
    success

    # The link is typically: /schools/:id?school_permission_key=valid_key
    # 'Back to Central Crossing' or similar text
    assert_select "a[href=?]", school_path(id: @school.id), text: /Back to/
  end

  test "wrestler links do not contain school_permission_key when not used" do
    @tournament.update(is_public: false)
    sign_in_owner
    get_show
  
    assert_select "a[href=?]", new_wrestler_path(school: @school.id), text: "New Wrestler"
  
    @school.wrestlers.each do |wrestler|
      # Check only for the DELETE link, specifying 'data-method="delete"' to exclude profile links
      assert_select "a[href=?][data-method=delete]", wrestler_path(wrestler), count: 1
  
      # Check edit link
      assert_select "a[href=?]", edit_wrestler_path(wrestler), count: 1
    end
  end  
  # END SHOW PAGE PERMISSIONS

  # School permission key tests

  test "non logged in user can get show page when using valid school_permission_key" do
    @tournament.update(is_public: false)
    get_show(school_permission_key: @school_permission_key)
    success
  end

  test "non logged in user cannot get show page when using invalid school_permission_key" do
    @tournament.update(is_public: false)
    get_show(school_permission_key: "invalid-key")
    redirect
  end

  test "non logged in user can edit school with valid school_permission_key" do
    @tournament.update(is_public: false)
    get_edit(school_permission_key: @school_permission_key)
    success
  end

  test "non logged in user cannot edit school with invalid school_permission_key" do
    @tournament.update(is_public: false)
    get_edit(school_permission_key: "invalid-key")
    redirect
  end

  test "non logged in user can update school with valid school_permission_key" do
    @tournament.update(is_public: false)
    post_update(school_permission_key: @school_permission_key)
    assert_redirected_to tournament_path(@school.tournament_id)
  end

  test "non logged in user cannot update school with invalid school_permission_key" do
    @tournament.update(is_public: false)
    post_update(school_permission_key: "invalid-key")
    redirect
  end

  test "non logged in user cannot delete school with invalid school_permission_key" do
    @tournament.update(is_public: false)
    destroy(school_permission_key: "invalid-key")
    redirect
  end

  test "non logged in user cannot delete school with valid school_permission_key" do
    @tournament.update(is_public: false)
    destroy(school_permission_key: @school_permission_key)
    redirect
  end

  # Ensure school_permission_key is used in wrestler links
  test "wrestler links contain school_permission_key when used" do
    @tournament.update(is_public: false)
    get_show(school_permission_key: @school_permission_key)

    assert_select "a[href=?]", new_wrestler_path(school: @school.id, school_permission_key: @school_permission_key), text: "New Wrestler"
    
    @school.wrestlers.each do |wrestler|
      assert_select "a[href=?]", edit_wrestler_path(wrestler, school_permission_key: @school_permission_key)
      assert_select "a[href=?]", wrestler_path(wrestler, school_permission_key: @school_permission_key), method: :delete
    end
  end

  test "stats page with school_permission_key includes it in 'Back to School' link" do
    get :stats, params: { id: @school.id, school_permission_key: @school_permission_ke }
    success

    # The link is typically: /schools/:id?school_permission_key=valid_key
    # 'Back to Central Crossing' or similar text
    assert_select "a[href=?]", school_path(id: @school.id, school_permission_key: @school_permission_ke), text: /Back to/
  end
  # End school permission key tests
end
