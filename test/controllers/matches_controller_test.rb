require 'test_helper'
require "json"

class MatchesControllerTest < ActionController::TestCase
  # Remove Devise helpers since we're no longer using Devise
  # include Devise::Test::ControllerHelpers # Needed to sign in
  include ActionView::Helpers::DateHelper # Needed for time ago in words
  include ActionCable::TestHelper

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
    @request.env["HTTP_REFERER"] = "/tournaments/#{@tournament.id}/matches"
    get :stat, params: { id: @match.id }
    patch :update, params: { id: @match.id, match: {tournament_id: 1, mat_id: 1} }
  end
 
  def get_stat
    get :stat, params: { id: @match.id }
  end

  def get_state
    get :state, params: { id: @match.id }
  end

  def get_state_with_params(extra_params = {})
    get :state, params: { id: @match.id }.merge(extra_params)
  end

  def get_spectate(extra_params = {})
    get :spectate, params: { id: @match.id }.merge(extra_params)
  end

  def get_edit_assignment(extra_params = {})
    get :edit_assignment, params: { id: @match.id }.merge(extra_params)
  end

  def patch_update_assignment(extra_params = {})
    base = {
      id: @match.id,
      match: {
        mat_id: @match.mat_id,
        queue_position: 2
      }
    }
    patch :update_assignment, params: base.deep_merge(extra_params)
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

  test "logged in user should not get state match page if not owner" do
    sign_in_non_owner
    get_state
    redirect
  end

  test "logged school delegate should not get state match page if not owner" do
    sign_in_school_delegate
    get_state
    redirect
  end

  test "non logged in user should not get stat match page" do
    get_stat
    redirect
  end

  test "non logged in user should not get state match page" do
    get_state
    redirect
  end

  test "valid school permission key cannot get state match page" do
    school = @tournament.schools.first
    school.update!(permission_key: "valid-school-key")

    get_state_with_params(school_permission_key: "valid-school-key")
    assert_redirected_to "/static_pages/not_allowed"
  end

  test "invalid school permission key cannot get state match page" do
    school = @tournament.schools.first
    school.update!(permission_key: "valid-school-key")

    get_state_with_params(school_permission_key: "invalid-school-key")
    assert_redirected_to "/static_pages/not_allowed"
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

  test "stat match page renders basic score field when match is finished" do
    sign_in_owner
    @match.update!(finished: 1, winner_id: @match.w1, win_type: "Decision", score: "3-1")

    get_stat

    assert_response :success
    assert_includes response.body, "data-match-score-finished-value=\"true\""
    assert_includes response.body, "type=\"text\""
    assert_includes response.body, "name=\"match[score]\""
    assert_not_includes response.body, "id=\"dynamic-score-input\""
  end

  test "logged in tournament owner should get state match page" do
    sign_in_owner
    get_state
    success
  end

  test "logged in tournament delegate should get state match page" do
    sign_in_tournament_delegate
    get_state
    success
  end

  test "logged in school delegate cannot get spectate match page when tournament is not public" do
    @tournament.update!(is_public: false)
    sign_in_school_delegate
    get_spectate
    redirect
  end

  test "logged in user cannot get spectate match page when tournament is not public" do
    @tournament.update!(is_public: false)
    sign_in_non_owner
    get_spectate
    redirect
  end

  test "logged in tournament delegate can get spectate match page when tournament is not public" do
    @tournament.update!(is_public: false)
    sign_in_tournament_delegate
    get_spectate
    success
  end

  test "logged in tournament owner can get spectate match page when tournament is not public" do
    @tournament.update!(is_public: false)
    sign_in_owner
    get_spectate
    success
  end

  test "non logged in user cannot get spectate match page when tournament is not public" do
    @tournament.update!(is_public: false)
    get_spectate
    redirect
  end

  test "valid school permission key cannot get spectate match page when tournament is not public" do
    @tournament.update!(is_public: false)
    school = @tournament.schools.first
    school.update!(permission_key: "valid-school-key")

    get_spectate(school_permission_key: "valid-school-key")
    assert_redirected_to "/static_pages/not_allowed"
  end

  test "invalid school permission key cannot get spectate match page when tournament is not public" do
    @tournament.update!(is_public: false)
    school = @tournament.schools.first
    school.update!(permission_key: "valid-school-key")

    get_spectate(school_permission_key: "invalid-school-key")
    assert_redirected_to "/static_pages/not_allowed"
  end

  test "logged in school delegate can get spectate match page when tournament is public" do
    @tournament.update!(is_public: true)
    sign_in_school_delegate
    get_spectate
    success
  end

  test "logged in user can get spectate match page when tournament is public" do
    @tournament.update!(is_public: true)
    sign_in_non_owner
    get_spectate
    success
  end

  test "logged in tournament delegate can get spectate match page when tournament is public" do
    @tournament.update!(is_public: true)
    sign_in_tournament_delegate
    get_spectate
    success
  end

  test "logged in tournament owner can get spectate match page when tournament is public" do
    @tournament.update!(is_public: true)
    sign_in_owner
    get_spectate
    success
  end

  test "non logged in user can get spectate match page when tournament is public" do
    @tournament.update!(is_public: true)
    get_spectate
    success
  end

  test "spectate renders embedded scoreboard when match is unfinished" do
    @tournament.update!(is_public: true)
    @match.update!(finished: nil)

    get_spectate

    assert_response :success
    assert_includes response.body, "data-match-spectate-target=\"scoreboardContainer\""
    assert_includes response.body, "data-controller=\"match-scoreboard\""
    assert_includes response.body, "data-match-scoreboard-source-mode-value=\"websocket\""
    assert_includes response.body, "data-match-scoreboard-display-mode-value=\"embedded\""
    assert_includes response.body, "table table-bordered table-condensed"
    assert_includes response.body, "data-match-scoreboard-target=\"greenTimerIndicator\""
    assert_includes response.body, "data-match-scoreboard-target=\"redTimerIndicator\""
    assert_not_includes response.body, "live-score-last-result-#{@match.id}"
  end

  test "spectate hides embedded scoreboard when match is finished" do
    @tournament.update!(is_public: true)
    @match.update!(finished: 1, winner_id: @match.w1, win_type: "Decision", score: "3-1")

    get_spectate

    assert_response :success
    assert_not_includes response.body, "data-match-spectate-target=\"scoreboardContainer\""
  end

  test "posting a match update from match state redirects to all matches" do
    sign_in_owner
    get :state, params: { id: @match.id }
    patch :update, params: { id: @match.id, match: { score: "3-1", win_type: "Decision", winner_id: @match.w1, finished: 1 } }

    assert_redirected_to "/tournaments/#{@tournament.id}/matches"
  end

  test "state page renders hidden stat fields for generated stats submission" do
    sign_in_owner
    get_state

    assert_response :success
    assert_includes response.body, 'name="match[w1_stat]"'
    assert_includes response.body, 'name="match[w2_stat]"'
    assert_includes response.body, 'data-match-state-target="w1StatField"'
    assert_includes response.body, 'data-match-state-target="w2StatField"'
  end

  test "posting a match update from match state respects redirect_to param" do
    sign_in_owner
    get :state, params: { id: @match.id, redirect_to: "/mats/#{@match.mat_id}" }
    patch :update, params: {
      id: @match.id,
      redirect_to: "/mats/#{@match.mat_id}",
      match: { score: "3-1", win_type: "Decision", winner_id: @match.w1, finished: 1 }
    }

    assert_redirected_to "/mats/#{@match.mat_id}"
  end

  test "posting a match update broadcasts match data and cached scoreboard state" do
    sign_in_owner
    scoreboard_state = {
      "participantScores" => { "w1" => 3, "w2" => 1 },
      "metadata" => { "boutNumber" => @match.bout_number }
    }
    stream = MatchChannel.broadcasting_for(@match)
    ActionCable.server.pubsub.clear
    ActionCable.server.pubsub.broadcasts(stream).clear
    Rails.cache.write(
      "tournament:#{@match.tournament_id}:match:#{@match.id}:scoreboard_state",
      scoreboard_state
    )

    patch :update, params: {
      id: @match.id,
      match: {
        w1_stat: "T3",
        w2_stat: "E1",
        score: "3-1",
        win_type: "Decision",
        winner_id: @match.w1,
        finished: 1
      }
    }

    payload = JSON.parse(ActionCable.server.pubsub.broadcasts(stream).last)
    assert_equal(
      {
        "w1_stat" => "T3",
        "w2_stat" => "E1",
        "score" => "3-1",
        "win_type" => "Decision",
        "winner_id" => @match.w1,
        "winner_name" => @match.wrestler1.name,
        "finished" => 1,
        "scoreboard_state" => scoreboard_state
      },
      payload
    )
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

  test "stats page should load if a match does not have finished_at" do
    create_double_elim_tournament_single_weight(14, "Regular Double Elimination 1-8")
    user = users(:one)
    @tournament.user_id = user.id
    @tournament.save
    matches = @tournament.matches.reload
    match = matches.first
    sign_in_owner
    get :stat, params: { id: match.id }
    assert_response :success
  end

  test "stat page loads with the finished_at time ago in words when a match is already finished" do
    create_double_elim_tournament_single_weight(14, "Regular Double Elimination 1-8")
    user = users(:one)
    @tournament.user_id = user.id
    @tournament.save
    matches = @tournament.matches.reload
    match = matches.first
    match.winner_id = match.w1
    match.finished = 1
    match.win_type = "Pin"
    match.score = "2:03"
    match.save

    finished_at = match.reload.finished_at
    sign_in_owner
    get :stat, params: { id: match.id }
    # Check that the finished_at value is displayed on the page
    assert_response :success
    assert_includes @response.body, time_ago_in_words(finished_at), "time_ago_in_words(finished_at) should be displayed on the page"
  end

  test "tournament owner can view edit_assignment and execute update_assignment" do
    sign_in_owner
    get_edit_assignment
    assert_response :success

    patch_update_assignment
    assert_response :redirect
    assert_not_equal "/static_pages/not_allowed", @response.redirect_url&.sub("http://test.host", "")
  end

  test "tournament delegate can view edit_assignment and execute update_assignment" do
    sign_in_tournament_delegate
    get_edit_assignment
    assert_response :success

    patch_update_assignment
    assert_response :redirect
    assert_not_equal "/static_pages/not_allowed", @response.redirect_url&.sub("http://test.host", "")
  end

  test "school delegate cannot view edit_assignment or execute update_assignment" do
    sign_in_school_delegate
    get_edit_assignment
    assert_redirected_to "/static_pages/not_allowed"

    patch_update_assignment
    assert_redirected_to "/static_pages/not_allowed"
  end

  test "non logged in user cannot view edit_assignment or execute update_assignment" do
    get_edit_assignment
    assert_redirected_to "/static_pages/not_allowed"

    patch_update_assignment
    assert_redirected_to "/static_pages/not_allowed"
  end

  test "logged in user without delegations cannot view edit_assignment or execute update_assignment" do
    sign_in_non_owner
    get_edit_assignment
    assert_redirected_to "/static_pages/not_allowed"

    patch_update_assignment
    assert_redirected_to "/static_pages/not_allowed"
  end

  test "valid school permission key cannot view edit_assignment or execute update_assignment" do
    school = @tournament.schools.first
    school.update!(permission_key: "valid-school-key")

    get_edit_assignment(school_permission_key: "valid-school-key")
    assert_redirected_to "/static_pages/not_allowed"

    patch_update_assignment(school_permission_key: "valid-school-key")
    assert_redirected_to "/static_pages/not_allowed"
  end

  test "invalid school permission key cannot view edit_assignment or execute update_assignment" do
    school = @tournament.schools.first
    school.update!(permission_key: "valid-school-key")

    get_edit_assignment(school_permission_key: "invalid-school-key")
    assert_redirected_to "/static_pages/not_allowed"

    patch_update_assignment(school_permission_key: "invalid-school-key")
    assert_redirected_to "/static_pages/not_allowed"
  end
end
