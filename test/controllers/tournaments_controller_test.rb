require 'test_helper'

class TournamentsControllerTest < ActionController::TestCase
  # Remove Devise helpers since we're no longer using Devise
  # include Devise::Test::ControllerHelpers

  setup do
     @tournament = Tournament.find(1)
    # @tournament.generateMatchups
     @school = @tournament.schools.first
     @wrestlers = @tournament.weights.first.wrestlers
     @adjust = Teampointadjust.find(1)
  end

  def post_update
    patch :update, params: { id: 1, tournament: {name: @tournament.name} }
  end

  def get_bracket
    get :up_matches, params: { id: 1 }
  end

  def get_all_brackets
    get :all_brackets, params: { id: 1 }
  end

  def get_up_matches
    get :up_matches, params: { id: 1 }
  end

  def get_qrcode(params = {})
    get :qrcode, params: { id: 1 }.merge(params)
  end
 
  def get_edit
    get :edit, params: { id: 1 }
  end

  def sign_in_owner
    sign_in users(:one)
  end

  def sign_in_non_owner
    sign_in users(:two)
  end
  
  def sign_in_delegate
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

  def redirect_tournament_error
    assert_redirected_to "/tournaments/#{@tournament.id}/error"
  end

  def destroy
    delete :destroy, params: { id: 1 }
  end

  def no_matches
    assert_redirected_to "/tournaments/#{@tournament.id}/no_matches"
  end
  
  def wipe
    @tournament.destroy_all_matches
  end

  test "logged in tournament owner can generate matches" do
    sign_in_owner
    get :generate_matches, params: { id: 1 }
    success
  end

  test "logged in non tournament owner cannot generate matches" do
    sign_in_non_owner
    get :generate_matches, params: { id: 1 }
    redirect
  end
  
  test "logged in school delegate cannot generate matches" do
    sign_in_school_delegate
    get :generate_matches, params: { id: 1 }
    redirect
  end

  test "logged in tournament owner can create custom weights" do
    sign_in_owner
    get :create_custom_weights, params: { id: 1, customValue: 'hs' } 
    assert_redirected_to '/tournaments/1'
  end

  test "logged in non tournament owner cannot create custom weights" do
    sign_in_non_owner
    get :create_custom_weights, params: { id: 1, customValue: 'hs' }
    redirect
  end
  
  test "logged in school delegate cannot create custom weights" do
    sign_in_school_delegate
    get :create_custom_weights, params: { id: 1, customValue: 'hs' } 
    redirect
  end


  test "logged in tournament owner can access weigh_ins" do
    sign_in_owner
    get :weigh_in, params: { id: 1 }
    success
    assert_not_includes response.body, "Weights were successfully recorded."
  end

  test "printable weigh in sheet includes wrestler name school weight class and actual weight" do
    sign_in_owner
    @tournament.update!(weigh_in_ref: "Ref Smith")
    wrestler = @tournament.weights.first.wrestlers.first
    wrestler.update!(
      name: "Printable Test Wrestler",
      offical_weight: 106.4
    )
    school = wrestler.school

    get :weigh_in_sheet, params: { id: @tournament.id, print: true }
    assert_response :success

    assert_includes response.body, school.name
    assert_includes response.body, "Printable Test Wrestler"
    assert_includes response.body, wrestler.weight.max.to_s
    assert_includes response.body, "106.4"
    assert_includes response.body, "Actual Weight"
    assert_includes response.body, "Weigh In Ref:"
    assert_includes response.body, "Ref Smith"
  end

  test "logged in non tournament owner cannot access weigh_ins" do
    sign_in_non_owner
    get :weigh_in, params: { id: 1 }
    redirect    
  end
  
  test "logged in school delegate cannot access weigh_ins" do
    sign_in_school_delegate
    get :weigh_in, params: { id: 1 }
    redirect    
  end

  test "logged in tournament owner can access weigh_in_weight" do
    sign_in_owner
    get :weigh_in, params: { id: 1, weight: 1 }
    success
  end

  test "logged in non tournament owner cannot access weigh_in_weight" do
    sign_in_non_owner
    get :weigh_in_weight, params: { id: 1, weight: 1 }
    redirect    
  end
  
  test "logged in school delegate cannot access weigh_in_weight" do
    sign_in_school_delegate
    get :weigh_in_weight, params: { id: 1, weight: 1 }
    redirect    
  end
  
  test "logged in tournament owner can access post weigh_in_weight" do
    sign_in_owner
    post :weigh_in, params: { id: 1, weight: 1, wrestler: @wrestlers }
    success
  end

  test "logged in tournament owner can save wrestler actual weight on weigh in weight page" do
    sign_in_owner
    wrestler = @tournament.weights.first.wrestlers.first

    post :weigh_in_weight, params: {
      id: @tournament.id,
      weight: wrestler.weight_id,
      wrestler: {
        wrestler.id.to_s => { offical_weight: "108.2" }
      }
    }

    assert_redirected_to "/tournaments/#{@tournament.id}/weigh_in/#{wrestler.weight_id}"
    assert_equal "Weights were successfully recorded.", flash[:notice]
    assert_equal 108.2, wrestler.reload.offical_weight.to_f

    get :weigh_in_weight, params: { id: @tournament.id, weight: wrestler.weight_id }
    assert_response :success
    assert_equal 1, response.body.scan("Weights were successfully recorded.").size
  end

  test "logged in non tournament owner cannot access post weigh_in_weight" do
    sign_in_non_owner
    post :weigh_in_weight, params: { id: 1, weight: 1, wrestler: @wrestlers }
    redirect    
  end
  
  test "logged in school delegate cannot access post weigh_in_weight" do
    sign_in_school_delegate
    post :weigh_in_weight, params: { id: 1, weight: 1, wrestler: @wrestlers }
    redirect    
  end


  test "logged in tournament owner should get edit tournament page" do
    sign_in_owner
    get_edit
    success
  end

  test "logged in user should not get edit tournament page if not owner" do
    sign_in_non_owner
    get_edit
    redirect
  end
  
  test "logged in school delegate should not get edit tournament page if not owner" do
    sign_in_school_delegate
    get_edit
    redirect
  end

  test "non logged in user should not get edit tournament page" do
    get_edit
    redirect
  end

  test "non logged in user should get post update tournament" do
    post_update
    assert_redirected_to '/static_pages/not_allowed' 
  end 

  test "logged in non owner and non delegate cannot access qrcode" do
    sign_in_non_owner
    get_qrcode
    redirect
  end

  test "non logged in user cannot access qrcode" do
    get_qrcode
    redirect
  end

  test "non logged in user with valid school permission key cannot access qrcode" do
    @school.update(permission_key: "valid-key")
    get_qrcode(school_permission_key: "valid-key")
    redirect
  end

  test "non logged in user with invalid school permission key cannot access qrcode" do
    @school.update(permission_key: "valid-key")
    get_qrcode(school_permission_key: "invalid-key")
    redirect
  end

  test "logged in owner can access qrcode" do
    sign_in_owner
    get_qrcode
    success
  end

  test "logged in tournament delegate can access qrcode" do
    sign_in_delegate
    get_qrcode
    success
  end

  test "logged in school delegate cannot access qrcode" do
    sign_in_school_delegate
    get_qrcode
    redirect
  end

  test "logged in user should not post update tournament if not owner" do
    sign_in_non_owner
    post_update
    assert_redirected_to '/static_pages/not_allowed' 
  end 
  
  test "logged in school delegate should not post update tournament if not owner" do
    sign_in_school_delegate
    post_update
    assert_redirected_to '/static_pages/not_allowed' 
  end

  test "logged in tournament owner should post update tournament" do
    sign_in_owner
    post_update
    assert_redirected_to tournament_path(1) 
  end


  test "logged in tournament owner can destroy a tournament" do
    sign_in_owner
    destroy
    assert_redirected_to tournaments_path
  end

  test "logged in user not tournament owner cannot destroy tournament" do
    sign_in_non_owner
    destroy
    redirect
  end
  
  test "logged in school delegate not tournament owner cannot destroy tournament" do
    sign_in_school_delegate
    destroy
    redirect
  end
  
  # BRACKETS PAGE PERMISSIONS WHEN TOURNAMENT IS NOT PUBLIC
  test "logged in school delegate cannot get bracket page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_school_delegate
    get_bracket
    redirect
  end
  
  test "logged in user cannot get bracket page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_non_owner
    get_bracket
    redirect
  end
  
  test "logged in tournament delegate can get bracket page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_delegate
    get_bracket
    success
  end
  
  test "logged in tournament owner can get bracket page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_owner
    get_bracket
    success
  end
  
  test "non logged in user cannot get bracket page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    get_bracket
    redirect 
  end
  
  # BRACKETS PAGE PERMISSIONS WHEN TOURNAMENT IS PUBLIC
  test "logged in school delegate can get bracket page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    sign_in_school_delegate
    get_bracket
    success
  end
  
  test "logged in user can get bracket page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    sign_in_non_owner
    get_bracket
    success
  end
  
  test "logged in tournament delegate can get bracket page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    sign_in_delegate
    get_bracket
    success
  end
  
  test "logged in tournament owner can get bracket page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    sign_in_owner
    get_bracket
    success
  end
  
  test "non logged in user can get bracket page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    get_bracket
    success 
  end
  # END BRACKETS PAGE PERMISSIONS

  # ALL BRACKETS PAGE PERMISSIONS WHEN TOURNAMENT IS NOT PUBLIC
  test "logged in school delegate cannot get all brackets page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_school_delegate
    get_all_brackets
    redirect
  end
  
  test "logged in user cannot get all brackets page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_non_owner
    get_all_brackets
    redirect
  end
  
  test "logged in tournament delegate can get all brackets page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_delegate
    get_all_brackets
    success
  end
  
  test "logged in tournament owner can get all brackets page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_owner
    get_all_brackets
    success
  end
  
  test "non logged in user cannot get all brackets page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    get_all_brackets
    redirect 
  end
  
  # ALL BRACKETS PAGE PERMISSIONS WHEN TOURNAMENT IS PUBLIC
  test "logged in school delegate can get all brackets page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    sign_in_school_delegate
    get_all_brackets
    success
  end
  
  test "logged in user can get all brackets page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    sign_in_non_owner
    get_all_brackets
    success
  end
  
  test "logged in tournament delegate can get all brackets page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    sign_in_delegate
    get_all_brackets
    success
  end
  
  test "logged in tournament owner can get all brackets page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    sign_in_owner
    get_all_brackets
    success
  end
  
  test "non logged in user can get all brackets page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    get_all_brackets
    success 
  end
  # END ALL BRACKETS PAGE PERMISSIONS

  # UP MATCHES PAGE PERMISSIONS WHEN TOURNAMENT IS NOT PUBLIC
  test "logged in school delegate cannot get up matches page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_school_delegate
    get_up_matches
    redirect
  end
  
  test "logged in user cannot get up matches page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_non_owner
    get_up_matches
    redirect
  end
  
  test "logged in tournament delegate can get up matches page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_delegate
    get_up_matches
    success
  end
  
  test "logged in tournament owner can get up matches page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_owner
    get_up_matches
    success
  end
  
  test "non logged in user cannot get up matches page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    get_up_matches
    redirect 
  end
  
  # UP MATCHES PAGE PERMISSIONS WHEN TOURNAMENT IS PUBLIC
  test "logged in school delegate can get up matches page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    sign_in_school_delegate
    get_up_matches
    success
  end
  
  test "logged in user can get up matches page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    sign_in_non_owner
    get_up_matches
    success
  end
  
  test "logged in tournament delegate can get up matches page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    sign_in_delegate
    get_up_matches
    success
  end
  
  test "logged in tournament owner can get up matches page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    sign_in_owner
    get_up_matches
    success
  end
  
  test "non logged in user can get up matches page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    get_up_matches
    success 
  end

  test "up matches uses turbo stream updates instead of timer refresh script" do
    @tournament.is_public = true
    @tournament.save
    get_up_matches
    success
    assert_includes response.body, "turbo-cable-stream-source"
    assert_includes response.body, "data-controller=\"up-matches-connection\""
    assert_includes response.body, "up-matches-cable-status-indicator"
    assert_not_includes response.body, "This page reloads every 30s"
  end

  test "up matches shows full screen button when print param is not true" do
    @tournament.is_public = true
    @tournament.save
    get :up_matches, params: { id: @tournament.id }
    assert_response :success

    assert_includes response.body, "Show Bout Board in Full Screen"
    assert_includes response.body, "print=true"
  end

  test "up matches hides full screen button when print param is true" do
    @tournament.is_public = true
    @tournament.save
    get :up_matches, params: { id: @tournament.id, print: "true" }
    assert_response :success

    assert_not_includes response.body, "Show Bout Board in Full Screen"
  end
  # END UP MATCHES PAGE PERMISSIONS

  # ALL_RESULTS PAGE PERMISSIONS WHEN TOURNAMENT IS NOT PUBLIC
  test "logged in school delegate cannot get all_results page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_school_delegate
    get :all_results, params: { id: 1 }
    redirect
  end
  
  test "logged in user cannot get all_results page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_non_owner
    get :all_results, params: { id: 1 }
    redirect
  end
  
  test "logged in tournament delegate can get all_results page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_delegate
    get :all_results, params: { id: 1 }
    success
  end
  
  test "logged in tournament owner can get all_results page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    sign_in_owner
    get :all_results, params: { id: 1 }
    success
  end
  
  test "non logged in user cannot get all_results page when tournament is not public" do
    @tournament.is_public = false
    @tournament.save
    get :all_results, params: { id: 1 }
    redirect 
  end
  
  # ALL_RESULTS PAGE PERMISSIONS WHEN TOURNAMENT IS PUBLIC
  test "logged in school delegate can get all_results page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    sign_in_school_delegate
    get :all_results, params: { id: 1 }
    success
  end
  
  test "logged in user can get all_results page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    sign_in_non_owner
    get :all_results, params: { id: 1 }
    success
  end
  
  test "logged in tournament delegate can get all_results page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    sign_in_delegate
    get :all_results, params: { id: 1 }
    success
  end
  
  test "logged in tournament owner can get all_results page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    sign_in_owner
    get :all_results, params: { id: 1 }
    success
  end
  
  test "non logged in user can get all_results page when tournament is public" do
    @tournament.is_public = true
    @tournament.save
    get :all_results, params: { id: 1 }
    success 
  end
  # END ALL_RESULTS PAGE PERMISSIONS

#TESTS THAT NEED MATCHES PUT ABOVE THIS
  test "up_matches renders when no matches exist" do
    sign_in_owner
    wipe
    get :up_matches, params: { id: 1 }
    success
  end
  
  test "redirect bracket if no matches" do
    sign_in_owner
    wipe
    get :bracket, params: { id: 1, weight: 1 }
    no_matches
  end
  
  test "logged in tournament delegate can generate matches" do
    sign_in_delegate
    get :generate_matches, params: { id: 1 }
    success
  end

  test "logged in tournament delegate can create custom weights" do
    sign_in_delegate
    get :create_custom_weights, params: { id: 1, customValue: 'hs' }
    assert_redirected_to '/tournaments/1'
  end

  test "logged in tournament delegate can access weigh_ins" do
    sign_in_delegate
    get :weigh_in, params: { id: 1 }
    success
  end

  test "logged in tournament delegate can access weigh_in_weight" do
    sign_in_delegate
    get :weigh_in, params: { id: 1, weight: 1 }
    success
  end
  
  test "logged in tournament delegate should get edit tournament page" do
    sign_in_delegate
    get_edit
    success
  end
  
  test "logged in tournament delegate can access post weigh_in_weight" do
    sign_in_delegate
    post :weigh_in, params: { id: 1, weight: 1, wrestler: @wrestlers }
    success
  end
  
  test "logged in tournament delegate should post update tournament" do
    sign_in_delegate
    post_update
    assert_redirected_to tournament_path(1) 
  end


  test "logged in tournament delegate cannot destroy a tournament" do
    sign_in_delegate
    destroy
    redirect
  end
  
  test 'logged in tournament owner can delegate a user' do
    sign_in_owner
    get :delegate, params: { id: 1 }
    success
  end
  
  test 'logged in tournament delegate cannot delegate a user' do
    sign_in_delegate
    get :delegate, params: { id: 1 }
    redirect
  end
  
  test 'logged in tournament owner can delegate a school user' do
    sign_in_owner
    get :school_delegate, params: { id: 1 }
    success
  end
  
  test 'logged in tournament delegate can delegate a school user' do
    sign_in_delegate
    get :school_delegate, params: { id: 1 }
    success
  end

  test "delegate page renders created tournament delegate in html" do
    user = User.create!(
      email: "tournament_delegate_render_#{SecureRandom.hex(4)}@example.com",
      password: "password"
    )
    TournamentDelegate.create!(tournament_id: @tournament.id, user_id: user.id)

    sign_in_owner
    get :delegate, params: { id: @tournament.id }
    assert_response :success
    assert_includes response.body, user.email
  end

  test "school_delegate page renders created school delegate in html" do
    user = User.create!(
      email: "school_delegate_render_#{SecureRandom.hex(4)}@example.com",
      password: "password"
    )
    SchoolDelegate.create!(school_id: @school.id, user_id: user.id)

    sign_in_owner
    get :school_delegate, params: { id: @tournament.id }
    assert_response :success
    assert_includes response.body, user.email
    assert_includes response.body, @school.name
  end
  
  test 'logged in tournament owner can delete a school delegate' do
    sign_in_owner
    patch :remove_school_delegate, params: { id: 1, delegate: SchoolDelegate.find(1) }
    assert_redirected_to "/tournaments/#{@tournament.id}/school_delegate"
  end
  
  test 'logged in tournament delegate can delete a school delegate' do
    sign_in_delegate
    patch :remove_school_delegate, params: { id: 1, delegate: SchoolDelegate.find(1) }
    assert_redirected_to "/tournaments/#{@tournament.id}/school_delegate"
  end
  
  test 'logged in tournament owner can delete a delegate' do
    sign_in_owner
    patch :remove_delegate, params: { id: 1, delegate: TournamentDelegate.find(1) }
    assert_redirected_to "/tournaments/#{@tournament.id}/delegate"
  end
  
  test 'logged in tournament delegate cannot delete a delegate' do
    sign_in_delegate
    patch :remove_delegate, params: { id: 1, delegate: TournamentDelegate.find(1) }
    redirect
  end
    
  test 'logged in tournament delegate can adjust team points' do
    sign_in_delegate
    get :teampointadjust, params: { id: 1 }
    success
  end
  
  test 'logged in tournament owner can adjust team points' do
    sign_in_owner
    get :teampointadjust, params: { id: 1 }
    success
  end

  test "teampointadjust page lists created point deduction once in html" do
    sign_in_owner
    school = School.create!(name: "Point Deduction School #{SecureRandom.hex(3)}", tournament_id: @tournament.id)
    adjustment = Teampointadjust.create!(school_id: school.id, points: 9876.5)

    get :teampointadjust, params: { id: @tournament.id }
    assert_response :success
    assert_equal 1, response.body.scan(adjustment.points.to_s).size
  end
  
  test 'logged in tournament delegate cannot adjust team points' do
    sign_in_school_delegate
    get :teampointadjust, params: { id: 1 }
    redirect
  end
  
  test 'logged in tournament owner can delete team point adjust' do
    sign_in_owner
    post :remove_teampointadjust, params: { id: 1, teampointadjust: Teampointadjust.find(1) }
    assert_redirected_to "/tournaments/#{@tournament.id}/teampointadjust"
  end
  
  test 'logged in tournament delegate can team point adjust' do
    sign_in_delegate
    post :remove_teampointadjust, params: { id: 1, teampointadjust: Teampointadjust.find(1) }
    assert_redirected_to "/tournaments/#{@tournament.id}/teampointadjust"
  end
  
  test 'logged in school delegate cannot delete team point adjust' do
    sign_in_school_delegate
    post :remove_teampointadjust, params: { id: 1, teampointadjust: Teampointadjust.find(1) }
    redirect
  end

  test 'logged in non owner should not get all matches page' do
    sign_in_non_owner
    get :matches, params: { id: 1 }
    redirect
  end

  test 'logged in owner should get all matches page' do
    sign_in_owner
    get :matches, params: { id: 1 } 
    success
  end

  test "matches page search finds by wrestler name, school name, and bout number" do
    sign_in_owner

    search_school = School.create!(name: "Search Prep Academy", tournament_id: @tournament.id)
    search_wrestler = Wrestler.create!(
      name: "Alpha Searchman",
      school_id: search_school.id,
      weight_id: @tournament.weights.first.id,
      original_seed: 99,
      bracket_line: 99,
      season_loss: 0,
      season_win: 0,
      pool: 1
    )
    match = Match.create!(
      tournament_id: @tournament.id,
      weight_id: @tournament.weights.first.id,
      bout_number: 888999,
      w1: search_wrestler.id,
      w2: @wrestlers.first.id,
      bracket_position: "Pool",
      round: 1
    )

    get :matches, params: { id: @tournament.id, search: "Searchman" }
    assert_response :success
    assert_includes response.body, match.bout_number.to_s

    get :matches, params: { id: @tournament.id, search: "Search Prep" }
    assert_response :success
    assert_includes response.body, match.bout_number.to_s

    get :matches, params: { id: @tournament.id, search: "888999" }
    assert_response :success
    assert_includes response.body, match.bout_number.to_s
  end

  test "matches page paginates filtered results" do
    sign_in_owner

    paging_school = School.create!(name: "Pager Academy", tournament_id: @tournament.id)
    paging_wrestler = Wrestler.create!(
      name: "Pager Wrestler",
      school_id: paging_school.id,
      weight_id: @tournament.weights.first.id,
      original_seed: 100,
      bracket_line: 100,
      season_loss: 0,
      season_win: 0,
      pool: 1
    )

    55.times do |i|
      Match.create!(
        tournament_id: @tournament.id,
        weight_id: @tournament.weights.first.id,
        bout_number: 910000 + i,
        w1: paging_wrestler.id,
        w2: @wrestlers.first.id,
        bracket_position: "Pool",
        round: 1
      )
    end

    get :matches, params: { id: @tournament.id, search: "Pager Academy" }
    assert_response :success
    assert_includes response.body, "Showing 1 - 50 of 55 matches"
    assert_includes response.body, "910000"
    assert_not_includes response.body, "910054"

    get :matches, params: { id: @tournament.id, search: "Pager Academy", page: 2 }
    assert_response :success
    assert_includes response.body, "Showing 51 - 55 of 55 matches"
    assert_includes response.body, "910054"
    assert_not_includes response.body, "910000"
  end

  test "logged in tournament owner can calculate team scores" do
    sign_in_owner
    post :calculate_team_scores, params: { id: 1 }
    assert_redirected_to "/tournaments/#{@tournament.id}"
  end

  test "logged in tournament delegate can calculate team scores" do
    sign_in_delegate
    post :calculate_team_scores, params: { id: 1 }
    assert_redirected_to "/tournaments/#{@tournament.id}"
  end

  test "logged in non tournament owner cannot calculate team scores" do
    sign_in_non_owner
    post :calculate_team_scores, params: { id: 1 }
    redirect
  end
  
  test "logged in school delegate cannot calculate team scores" do
    sign_in_school_delegate
    post :calculate_team_scores, params: { id: 1 }
    redirect
  end

  test "only owner can set user_id when creating a new tournament" do
    # Sign in as owner and create a new tournament
    sign_in_owner
    post :create, params: { tournament: { name: 'New Tournament', address: '123 Main St', director: 'Director', director_email: 'director@example.com', date: '2024-01-01', tournament_type: 'Pool to bracket', is_public: false } }
    new_tournament = Tournament.last
    assert_equal users(:one).id, new_tournament.user_id, "The owner should be assigned as the user_id on creation"
  
    # Sign in as non-owner and try to update the tournament without changing user_id
    sign_in_non_owner
    patch :update, params: { id: new_tournament.id, tournament: { name: 'Updated Tournament', is_public: true } }
    updated_tournament = Tournament.find(new_tournament.id)
    assert_equal users(:one).id, updated_tournament.user_id, "The user_id should not change when the tournament is edited by a non-owner"
  end

  test "tournament generation error when a wrestler has an original seed higher than the amount of wrestlers in the weight" do
    sign_in_owner
    create_double_elim_tournament_single_weight(14, "Regular Double Elimination 1-8")
    @tournament.destroy_all_matches
    @tournament.user_id = 1
    @tournament.save
    wrestler = @tournament.weights.first.wrestlers.first
    wrestler.original_seed = 15
    wrestler.save
    get :generate_matches, params: { id: @tournament.id }
    redirect_tournament_error
  end

  test "tournament generation error when a double elimination tournament has too many wrestlers" do
    sign_in_owner
    create_double_elim_tournament_single_weight(16, "Regular Double Elimination 1-8")
    @tournament.destroy_all_matches
    @tournament.user_id = 1
    @tournament.save
    create_wrestlers_for_weight_for_double_elim(@tournament.weights.first, @tournament.schools.first, 1, 20)
    get :generate_matches, params: { id: @tournament.id }
    redirect_tournament_error
  end

  test "tournament generation error when a double elimination tournament has too few wrestlers" do
    sign_in_owner
    create_double_elim_tournament_single_weight(4, "Regular Double Elimination 1-8")
    @tournament.destroy_all_matches
    @tournament.user_id = 1
    @tournament.save
    @tournament.weights.first.wrestlers.first.destroy
    get :generate_matches, params: { id: @tournament.id }
    redirect_tournament_error
  end

  test "tournament generation error when a Modified 16 Man Double Elimination tournament has too many wrestlers" do
    sign_in_owner
    create_double_elim_tournament_single_weight(16, "Modified 16 Man Double Elimination 1-8")
    @tournament.destroy_all_matches
    @tournament.user_id = 1
    @tournament.save
    create_wrestlers_for_weight_for_double_elim(@tournament.weights.first, @tournament.schools.first, 1, 20)
    get :generate_matches, params: { id: @tournament.id }
    redirect_tournament_error
  end

  test "tournament generation error when a Modified 16 Man Double Elimination tournament has too few wrestlers" do
    sign_in_owner
    create_double_elim_tournament_single_weight(12, "Modified 16 Man Double Elimination 1-8")
    @tournament.destroy_all_matches
    @tournament.user_id = 1
    @tournament.save
    @tournament.weights.first.wrestlers.first.destroy
    get :generate_matches, params: { id: @tournament.id }
    redirect_tournament_error
  end

  test "tournament generation error when a pool to bracket tournament has too many wrestlers" do
    sign_in_owner
    create_pool_tournament_single_weight(24)
    @tournament.destroy_all_matches
    @tournament.user_id = 1
    @tournament.save
    create_wrestlers_for_weight(@tournament.weights.first, @tournament.schools.first, 1, 20)
    get :generate_matches, params: { id: @tournament.id }
    redirect_tournament_error
  end

  test "tournament generation error when a pool to bracket tournament has too few wrestlers" do
    sign_in_owner
    create_pool_tournament_single_weight(2)
    @tournament.destroy_all_matches
    @tournament.user_id = 1
    @tournament.save
    @tournament.weights.first.wrestlers.first.destroy
    get :generate_matches, params: { id: @tournament.id }
    redirect_tournament_error
  end

  test "tournament generation error when two wrestlers in a weight class have the same original_seed" do
    sign_in_owner
    create_pool_tournament_single_weight(5)
    @tournament.destroy_all_matches
    @tournament.user_id = 1
    @tournament.save
    wrestler = @tournament.weights.first.wrestlers.second
    wrestler.original_seed = 1
    wrestler.save
    get :generate_matches, params: { id: @tournament.id }
    redirect_tournament_error
  end

  test "tournament generation error when a weight class has wrestlers with out-of-order original seeds" do
    sign_in_owner
    create_pool_tournament_single_weight(5) # Create a weight class with 5 wrestlers
    @tournament.destroy_all_matches
    @tournament.user_id = 1
    @tournament.save
  
    # Set seeds to have a gap: [1, 2, 3, 5, nil]
    wrestlers = @tournament.weights.first.wrestlers
    wrestlers[0].original_seed = 1
    wrestlers[1].original_seed = 2
    wrestlers[2].original_seed = 3
    wrestlers[3].original_seed = 5
    wrestlers[4].original_seed = nil # Unseeded wrestler
    wrestlers.each(&:save)
  
    get :generate_matches, params: { id: @tournament.id }
    redirect_tournament_error
  end

  test "logged in tournament owner can generate matches with the correct seed order" do
    sign_in_owner
    create_pool_tournament_single_weight(5) # Create a weight class with 5 wrestlers
    @tournament.destroy_all_matches
    @tournament.user_id = 1
    @tournament.save
  
    # Set seeds to have a gap: [1, 2, 3, 5, nil]
    wrestlers = @tournament.weights.first.wrestlers
    wrestlers[0].original_seed = 1
    wrestlers[1].original_seed = 2
    wrestlers[2].original_seed = 3
    wrestlers[3].original_seed = 4
    wrestlers[4].original_seed = nil # Unseeded wrestler
    wrestlers.each(&:save)
  
    get :generate_matches, params: { id: @tournament.id }
    success
  end

  test "tournament owner can create school keys" do
    sign_in_owner
    post :generate_school_keys, params: { id: @tournament.id }
    assert_redirected_to school_delegate_path(@tournament)
    assert_equal "School permission keys generated successfully.", flash[:notice]
  end
  
  test "tournament owner can delete school keys" do
    sign_in_owner
    post :delete_school_keys, params: { id: @tournament.id }
    # Update this path/notices if your controller redirects differently
    assert_redirected_to school_delegate_path(@tournament)
    assert_equal "All school permission keys have been deleted.", flash[:notice]
  end
  
  test "tournament delegate can create school keys" do
    sign_in_delegate
    post :generate_school_keys, params: { id: @tournament.id }
    assert_redirected_to school_delegate_path(@tournament)
    assert_equal "School permission keys generated successfully.", flash[:notice]
  end

  test "generated school permission keys are displayed on school delegate page" do
    sign_in_owner
    post :generate_school_keys, params: { id: @tournament.id }
    assert_redirected_to school_delegate_path(@tournament)

    @tournament.schools.reload.each do |school|
      assert_not_nil school.permission_key, "Expected permission key for school #{school.id}"
      assert_not_empty school.permission_key, "Expected non-empty permission key for school #{school.id}"
    end

    get :school_delegate, params: { id: @tournament.id }
    assert_response :success

    @tournament.schools.each do |school|
      expected_link_fragment = "/schools/#{school.id}?school_permission_key=#{school.permission_key}"
      assert_includes response.body, expected_link_fragment
    end
  end
  
  test "tournament delegate can delete school keys" do
    sign_in_delegate
    post :delete_school_keys, params: { id: @tournament.id }
    assert_redirected_to school_delegate_path(@tournament)
    assert_equal "All school permission keys have been deleted.", flash[:notice]
  end
  
  test "logged in non-owner cannot create school keys" do
    sign_in_non_owner
    post :generate_school_keys, params: { id: @tournament.id }
    redirect
  end
  
  test "logged in non-owner cannot delete school keys" do
    sign_in_non_owner
    post :delete_school_keys, params: { id: @tournament.id }
    redirect
  end
  
  test "non logged in user cannot create school keys" do
    # no sign_in
    post :generate_school_keys, params: { id: @tournament.id }
    redirect
  end
  
  test "non logged in user cannot delete school keys" do
    # no sign_in
    post :delete_school_keys, params: { id: @tournament.id }
    redirect
  end

  # TESTS FOR BRACKET MATCH RENDERING

  test "all match bout numbers render in double elimination bracket page" do
    sign_in_owner
    create_double_elim_tournament_single_weight(14, "Regular Double Elimination 1-8")
    
    get :bracket, params: { id: @tournament.id, weight: @tournament.weights.first.id }
    assert_response :success
    
    # Verify all bout numbers appear in the HTML response
    @tournament.matches.each do |match|
      assert_match(/#{match.bout_number}/, response.body, "Bout number #{match.bout_number} is missing from the bracket page")
    end
  end
  
  test "all match bout numbers render in modified double elimination bracket page" do
    sign_in_owner
    create_double_elim_tournament_single_weight(14, "Modified 16 Man Double Elimination 1-8")
    
    get :bracket, params: { id: @tournament.id, weight: @tournament.weights.first.id }
    assert_response :success
    
    # Verify all bout numbers appear in the HTML response
    @tournament.matches.each do |match|
      assert_match(/#{match.bout_number}/, response.body, "Bout number #{match.bout_number} is missing from the bracket page")
    end
  end
  
  test "all match bout numbers render in pool to bracket (two pools to semi) page" do
    sign_in_owner
    create_pool_tournament_single_weight(8)
    
    get :bracket, params: { id: @tournament.id, weight: @tournament.weights.first.id }
    assert_response :success
    
    # Verify all bracket match bout numbers appear in the HTML response
    @tournament.matches.where.not(bracket_position: "Pool").each do |match|
      assert_match(/#{match.bout_number}/, response.body, "Bout number #{match.bout_number} is missing from the bracket page")
    end
    
    # For pool matches, they should appear in the pool section
    pool_matches = @tournament.matches.where(bracket_position: "Pool")
    pool_matches.each do |match|
      assert_match(/#{match.bout_number}/, response.body, "Pool bout number #{match.bout_number} is missing from the bracket page")
    end
  end
  
  test "all match bout numbers render in pool to bracket (four pools to quarter) page" do
    sign_in_owner
    create_pool_tournament_single_weight(12)
    
    get :bracket, params: { id: @tournament.id, weight: @tournament.weights.first.id }
    assert_response :success
    
    # Verify all bracket match bout numbers appear in the HTML response
    @tournament.matches.where.not(bracket_position: "Pool").each do |match|
      assert_match(/#{match.bout_number}/, response.body, "Bout number #{match.bout_number} is missing from the bracket page")
    end
    
    # For pool matches, they should appear in the pool section
    pool_matches = @tournament.matches.where(bracket_position: "Pool")
    pool_matches.each do |match|
      assert_match(/#{match.bout_number}/, response.body, "Pool bout number #{match.bout_number} is missing from the bracket page")
    end
  end
  
  test "all match bout numbers render in pool to bracket (four pools to semi) page" do
    sign_in_owner
    create_pool_tournament_single_weight(16)
    
    get :bracket, params: { id: @tournament.id, weight: @tournament.weights.first.id }
    assert_response :success
    
    # Verify all bracket match bout numbers appear in the HTML response
    @tournament.matches.where.not(bracket_position: "Pool").each do |match|
      assert_match(/#{match.bout_number}/, response.body, "Bout number #{match.bout_number} is missing from the bracket page")
    end
    
    # For pool matches, they should appear in the pool section
    pool_matches = @tournament.matches.where(bracket_position: "Pool")
    pool_matches.each do |match|
      assert_match(/#{match.bout_number}/, response.body, "Pool bout number #{match.bout_number} is missing from the bracket page")
    end
  end
  
  test "all match bout numbers render in pool to bracket (two pools to final) page" do
    sign_in_owner
    create_pool_tournament_single_weight(10)
    
    get :bracket, params: { id: @tournament.id, weight: @tournament.weights.first.id }
    assert_response :success
    
    # Verify all bracket match bout numbers appear in the HTML response
    @tournament.matches.where.not(bracket_position: "Pool").each do |match|
      assert_match(/#{match.bout_number}/, response.body, "Bout number #{match.bout_number} is missing from the bracket page")
    end
    
    # For pool matches, they should appear in the pool section
    pool_matches = @tournament.matches.where(bracket_position: "Pool")
    pool_matches.each do |match|
      assert_match(/#{match.bout_number}/, response.body, "Pool bout number #{match.bout_number} is missing from the bracket page")
    end
  end
  
  test "all match bout numbers render in pool to bracket (eight pools) page" do
    sign_in_owner
    create_pool_tournament_single_weight(24)
    
    get :bracket, params: { id: @tournament.id, weight: @tournament.weights.first.id }
    assert_response :success
    
    # Verify all bracket match bout numbers appear in the HTML response
    @tournament.matches.where.not(bracket_position: "Pool").each do |match|
      assert_match(/#{match.bout_number}/, response.body, "Bout number #{match.bout_number} is missing from the bracket page")
    end
    
    # For pool matches, they should appear in the pool section
    pool_matches = @tournament.matches.where(bracket_position: "Pool")
    pool_matches.each do |match|
      assert_match(/#{match.bout_number}/, response.body, "Pool bout number #{match.bout_number} is missing from the bracket page")
    end
  end
  
  test "all match bout numbers render in double elimination 8-man bracket page" do
    sign_in_owner
    create_double_elim_tournament_single_weight_1_6(6)
    
    get :bracket, params: { id: @tournament.id, weight: @tournament.weights.first.id }
    assert_response :success
    
    # Verify all bout numbers appear in the HTML response
    @tournament.matches.each do |match|
      assert_match(/#{match.bout_number}/, response.body, "Bout number #{match.bout_number} is missing from the bracket page")
    end
  end
  
  test "all match bout numbers render in double elimination 32-man bracket page" do
    sign_in_owner
    create_double_elim_tournament_single_weight(30, "Regular Double Elimination 1-8")
    
    get :bracket, params: { id: @tournament.id, weight: @tournament.weights.first.id }
    assert_response :success
    
    # Verify all bout numbers appear in the HTML response
    @tournament.matches.each do |match|
      assert_match(/#{match.bout_number}/, response.body, "Bout number #{match.bout_number} is missing from the bracket page")
    end
  end
  test "index sorts tournaments by date closest to today" do
    today = Date.today
    t_today = Tournament.create!(name: "Closest Today", address: "123 Test St", director: "Director", director_email: "today@example.com", date: today, tournament_type: "Pool to bracket", is_public: true)
    t_minus1 = Tournament.create!(name: "Minus 1", address: "123 Test St", director: "Director", director_email: "m1@example.com", date: today - 1, tournament_type: "Pool to bracket", is_public: true)
    t_plus1 = Tournament.create!(name: "Plus 1", address: "123 Test St", director: "Director", director_email: "p1@example.com", date: today + 1, tournament_type: "Pool to bracket", is_public: true)
    t_plus2 = Tournament.create!(name: "Plus 2", address: "123 Test St", director: "Director", director_email: "p2@example.com", date: today + 2, tournament_type: "Pool to bracket", is_public: true)
    t_minus3 = Tournament.create!(name: "Minus 3", address: "123 Test St", director: "Director", director_email: "m3@example.com", date: today - 3, tournament_type: "Pool to bracket", is_public: true)
    t_plus10 = Tournament.create!(name: "Plus 10", address: "123 Test St", director: "Director", director_email: "p10@example.com", date: today + 10, tournament_type: "Pool to bracket", is_public: true)

    created = [t_today, t_minus1, t_plus1, t_plus2, t_minus3, t_plus10]
    # Hit index
    get :index
    assert_response :success

    # From the controller result, select only the tournaments we just created and verify their relative order
    results = assigns(:tournaments).select { |t| created.map(&:id).include?(t.id) }
    expected_order = created.sort_by { |t| (t.date - today).abs }.map(&:id)

    # Basic ordering assertions
    assert_equal expected_order, results.map(&:id), "Created tournaments should be ordered by distance from today"
    assert_equal t_today.id, results.first.id, "The tournament dated today should be first (closest)"
    assert_equal t_plus10.id, results.last.id, "The farthest tournament should appear last"

    # Relative order checks (smaller distance should appear before larger distance)
    assert results.index { |r| r.id == t_minus1.id } < results.index { |r| r.id == t_plus2.id }, "t_minus1 (distance 1) should appear before t_plus2 (distance 2)"
    assert results.index { |r| r.id == t_plus2.id } < results.index { |r| r.id == t_minus3.id }, "t_plus2 (distance 2) should appear before t_minus3 (distance 3)"
  end

  test "index paginates tournaments with page param and exposes total_count" do
    initial_count = Tournament.count
    # Create 25 tournaments to ensure we exceed the per_page (20)
    25.times do |i|
      Tournament.create!(name: "Paginate Test #{i}", address: "1 Paginate Rd", director: "Dir", director_email: "paginate#{i}@example.com", date: Date.today + i, tournament_type: "Pool to bracket", is_public: true)
    end
    expected_total = initial_count + 25

    # Page 1
    get :index, params: { page: 1 }
    assert_response :success
    assert_equal expected_total, assigns(:total_count), "total_count should reflect all tournaments"
    assert_equal 20, assigns(:tournaments).size, "first page should contain 20 tournaments"

    # Page 2
    get :index, params: { page: 2 }
    assert_response :success
    assert_equal expected_total, assigns(:total_count), "total_count should remain the same on subsequent pages"
    expected_page2_size = expected_total - 20
    # If there are more than 20 initial fixtures, expected_page2_size might be > 20; clamp to per_page logic:
    expected_page2_display = [expected_page2_size, 20].min
    assert_equal expected_page2_display, assigns(:tournaments).size, "second page should contain the remaining tournaments (or up to per_page)"
  end

  test "bout_sheets renders wrestler names, school names, and round for selected round" do
    tournament = create_double_elim_tournament_single_weight(8, "Regular Double Elimination 1-6")
    tournament.update!(user_id: users(:one).id, is_public: true)
    sign_in_owner

    match = tournament.matches.where.not(w1: nil, w2: nil)
                             .where("loser1_name != ? OR loser1_name IS NULL", "BYE")
                             .where("loser2_name != ? OR loser2_name IS NULL", "BYE")
                             .order(:bout_number)
                             .first
    assert_not_nil match, "Expected at least one fully populated non-BYE match"

    round = match.round.to_s
    w1 = Wrestler.find(match.w1)
    w2 = Wrestler.find(match.w2)

    get :bout_sheets, params: { id: tournament.id, round: round }
    assert_response :success

    assert_includes response.body, "Bout Number:</strong> #{match.bout_number}"
    assert_includes response.body, "Round:</strong> #{match.round}"
    assert_includes response.body, "#{w1.name}-#{w1.school.name}"
    assert_includes response.body, "#{w2.name}-#{w2.school.name}"
  end

  test "bout_sheets filters out matches with BYE loser names" do
    tournament = create_double_elim_tournament_single_weight(8, "Regular Double Elimination 1-6")
    tournament.update!(user_id: users(:one).id, is_public: true)
    sign_in_owner

    bye_match = tournament.matches.order(:bout_number).first
    assert_not_nil bye_match, "Expected at least one match to mark as BYE"
    bye_match.update!(loser1_name: "BYE")

    non_bye_match = tournament.matches.where.not(id: bye_match.id).where.not(w1: nil, w2: nil)
                              .where("loser1_name != ? OR loser1_name IS NULL", "BYE")
                              .where("loser2_name != ? OR loser2_name IS NULL", "BYE")
                              .order(:bout_number)
                              .first
    assert_not_nil non_bye_match, "Expected at least one non-BYE match to remain"

    get :bout_sheets, params: { id: tournament.id, round: "All" }
    assert_response :success

    assert_not_includes response.body, "Bout Number:</strong> #{bye_match.bout_number}"
    assert_includes response.body, "Bout Number:</strong> #{non_bye_match.bout_number}"
  end
end
