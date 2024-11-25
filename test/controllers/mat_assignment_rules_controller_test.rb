require 'test_helper'

class MatAssignmentRulesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @tournament = tournaments(:one) # Existing fixture
    @mat = mats(:one)               # Existing fixture
  end

  # Controller actions for testing
  def index
    get :index, params: { tournament_id: @tournament.id }
  end

  def new
    get :new, params: { tournament_id: @tournament.id }
  end

  def create_rule
    post :create, params: { tournament_id: @tournament.id, mat_assignment_rule: { 
      mat_id: @mat.id, weight_classes: [1, 2, 3], bracket_positions: ['1/2'], rounds: [1, 2] 
    } }
  end

  def edit_rule(rule_id)
    get :edit, params: { tournament_id: @tournament.id, id: rule_id }
  end

  def update_rule(rule_id)
    patch :update, params: { tournament_id: @tournament.id, id: rule_id, mat_assignment_rule: { 
      weight_classes: [4, 5, 6] 
    } }
  end

  def destroy_rule(rule_id)
    delete :destroy, params: { tournament_id: @tournament.id, id: rule_id }
  end

  # User sign-in helpers
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

  # Assertion helpers
  def success
    assert_response :success
  end

  def redirect
    assert_redirected_to '/static_pages/not_allowed'
  end

  # Tests
  test "logged in tournament owner should get index" do
    sign_in_owner
    index
    success
  end

  test "logged in tournament delegate should get index" do
    sign_in_tournament_delegate
    index
    success
  end

  test "logged in user should not get index if not owner or delegate" do
    sign_in_non_owner
    index
    redirect
  end

  test "logged school delegate should not get index" do
    sign_in_school_delegate
    index
    redirect
  end

  test "logged in tournament owner should create a new rule" do
    sign_in_owner
    new
    success
    assert_difference 'MatAssignmentRule.count', 1 do
      create_rule
    end
    assert_redirected_to tournament_mat_assignment_rules_path(@tournament)
  end

  test "logged in tournament delegate should create a new rule" do
    sign_in_tournament_delegate
    new
    success
    assert_difference 'MatAssignmentRule.count', 1 do
      create_rule
    end
    assert_redirected_to tournament_mat_assignment_rules_path(@tournament)
  end

  test "logged in user should not create a rule if not owner or delegate" do
    sign_in_non_owner
    new
    redirect
    assert_no_difference 'MatAssignmentRule.count' do
      create_rule
    end
    redirect
  end

  test "logged school delegate should not create a rule" do
    sign_in_school_delegate
    new
    redirect
    assert_no_difference 'MatAssignmentRule.count' do
      create_rule
    end
    redirect
  end

  test "logged in tournament owner should edit a rule" do
    rule = MatAssignmentRule.create!(mat_id: @mat.id, tournament_id: @tournament.id, weight_classes: [1, 2, 3])
    sign_in_owner
    edit_rule(rule.id)
    success
  end

  test "logged in tournament delegate should edit a rule" do
    rule = MatAssignmentRule.create!(mat_id: @mat.id, tournament_id: @tournament.id, weight_classes: [1, 2, 3])
    sign_in_tournament_delegate
    edit_rule(rule.id)
    success
  end

  test "logged in user should not edit a rule if not owner or delegate" do
    rule = MatAssignmentRule.create!(mat_id: @mat.id, tournament_id: @tournament.id, weight_classes: [1, 2, 3])
    sign_in_non_owner
    edit_rule(rule.id)
    redirect
  end

  test "logged school delegate should not edit a rule" do
    rule = MatAssignmentRule.create!(mat_id: @mat.id, tournament_id: @tournament.id, weight_classes: [1, 2, 3])
    sign_in_school_delegate
    edit_rule(rule.id)
    redirect
  end

  test "logged in tournament owner should update a rule" do
    rule = MatAssignmentRule.create!(mat_id: @mat.id, tournament_id: @tournament.id, weight_classes: [1, 2, 3])
    sign_in_owner
    update_rule(rule.id)
    assert_redirected_to tournament_mat_assignment_rules_path(@tournament)
    rule.reload
    assert_equal [4, 5, 6], rule.weight_classes
  end

  test "logged in tournament delegate should update a rule" do
    rule = MatAssignmentRule.create!(mat_id: @mat.id, tournament_id: @tournament.id, weight_classes: [1, 2, 3])
    sign_in_tournament_delegate
    update_rule(rule.id)
    assert_redirected_to tournament_mat_assignment_rules_path(@tournament)
    rule.reload
    assert_equal [4, 5, 6], rule.weight_classes
  end

  test "logged in tournament owner should destroy a rule" do
    rule = MatAssignmentRule.create!(mat_id: @mat.id, tournament_id: @tournament.id, weight_classes: [1, 2, 3])
    sign_in_owner
    assert_difference 'MatAssignmentRule.count', -1 do
      destroy_rule(rule.id)
    end
    assert_redirected_to tournament_mat_assignment_rules_path(@tournament)
  end

  test "logged in tournament delegate should destroy a rule" do
    rule = MatAssignmentRule.create!(mat_id: @mat.id, tournament_id: @tournament.id, weight_classes: [1, 2, 3])
    sign_in_tournament_delegate
    assert_difference 'MatAssignmentRule.count', -1 do
      destroy_rule(rule.id)
    end
    assert_redirected_to tournament_mat_assignment_rules_path(@tournament)
  end

  test "logged in user should not destroy a rule if not owner or delegate" do
    rule = MatAssignmentRule.create!(mat_id: @mat.id, tournament_id: @tournament.id, weight_classes: [1, 2, 3])
    sign_in_non_owner
    assert_no_difference 'MatAssignmentRule.count' do
      destroy_rule(rule.id)
    end
    redirect
  end
end
