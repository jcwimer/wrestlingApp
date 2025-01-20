require 'test_helper'

class MatsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @tournament = Tournament.find(1)
    # @tournament.generateMatchups
    @match = Match.where("tournament_id = ? and mat_id = ?",1,1).first
    @mat = mats(:one)
  end
 
  def create
    post :create, params: { mat: {name: 'Mat100', tournament_id: 1} }
  end

  def post_assign_next_match
    post :assign_next_match, params: { id: @mat.id }
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

  def post_match_update_from_mat_show
    get :show, params: { id: @mat.id }
    old_controller = @controller
    @controller = MatchesController.new
    patch :update, params: { id: @match.id, match: {tournament_id: 1, mat_id: @mat.id} }
    @controller = old_controller
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

  test "redirect to mat show when posting a match from mat show" do
    sign_in_owner
    post_match_update_from_mat_show
    assert_redirected_to "/mats/#{@mat.id}"
  end

  test "logged in tournament owner can show mat with bout_number param" do
    sign_in_owner
  
    # Set a specific bout number to test
    bout_number = @match.bout_number
  
    # Call the show action with the bout_number param
    get :show, params: { id: @mat.id, bout_number: bout_number }
  
    # Assert the response is successful
    assert_response :success
  
    # Check if the bout_number is rendered on the page
    assert_match /#{bout_number}/, response.body, "The bout_number should be rendered on the page"
  end

  test "logged in tournament owner should redirect back to the first unfinished bout on a mat after submitting a match with a bout number param" do
    sign_in_owner
  
    first_bout_number = @mat.unfinished_matches.first.bout_number
  
    # Set a specific bout number to test
    bout_number = @match.bout_number
  
    # Call the show action with the bout_number param
    get :show, params: { id: @mat.id, bout_number: bout_number }
  
    # Submit the match
    old_controller = @controller
    @controller = MatchesController.new
    patch :update, params: { id: @match.id, match: { tournament_id: 1, mat_id: @mat.id } }
    @controller = old_controller
  
    # Assert the redirect
    assert_redirected_to mat_path(@mat) # Verify redirection to /mats/1
  
    # Explicitly follow the redirect with the named route
    get :show, params: { id: @mat.id }
  
    # Check if the first_bout_number is rendered on the page
    assert_match /#{first_bout_number}/, response.body, "The first unfinished bout_number should be rendered on the page"
  end  
  
#TESTS THAT NEED MATCHES PUT ABOVE THIS
  test "redirect show if no matches" do
    sign_in_owner
    wipe
    show
    no_matches
  end

  # Assign Next Match Permissions
  test "logged in tournament owner should post assign_next_match mat page" do
    sign_in_owner
    post_assign_next_match
    assert_redirected_to "/tournaments/#{@mat.tournament_id}"
  end
  
  test "logged in tournament delegate should post assign_next_match mat page" do
    sign_in_tournament_delegate
    post_assign_next_match
    assert_redirected_to "/tournaments/#{@mat.tournament_id}"
  end

  test "logged in user should not get post assign_next_match page if not owner" do
    sign_in_non_owner
    post_assign_next_match
    redirect
  end
  
  test "logged school delegate should not post assign_next_match mat page if not owner" do
    sign_in_school_delegate
    post_assign_next_match
    redirect
  end

  test "non logged in user should not post assign_next_match mat page" do
    post_assign_next_match
    redirect
  end
end
