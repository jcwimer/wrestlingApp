# frozen_string_literal: true

require 'test_helper'

class InteractiveBracketsControllerTest < ActionController::TestCase
  tests TournamentsController

  setup do
    @tournament = Tournament.find(1)
  end

  def sign_in_owner
    sign_in users(:one)
  end

  test 'regular double elimination groups third place with consolation' do
    sign_in_owner
    create_double_elim_tournament_single_weight(14, 'Regular Double Elimination 1-8')

    get :bracket, params: { id: @tournament.id, weight: @tournament.weights.first.id }

    assert_response :success
    assert_select '[role="tab"]', text: 'Championship Bracket', count: 1
    assert_select '[role="tab"]', text: 'Consolation Bracket', count: 1
    assert_select '[role="tab"]', text: 'Placement Matches', count: 1
    assert_select '[id$="-panel-championship"] .interactive-bracket__round h3 button[data-action="bracket-navigation#goToRound"]', text: 'Semis', count: 1
    assert_select '[id$="-panel-consolation"] .interactive-bracket__round h3', text: '3/4', count: 1
    assert_select '[id$="-panel-placement"] .interactive-bracket__round h3', text: '5/6', count: 1
    assert_select '[id$="-panel-placement"] .interactive-bracket__round h3', text: '7/8', count: 1
  end

  test 'modified double elimination groups fifth place with consolation' do
    sign_in_owner
    create_double_elim_tournament_single_weight(14, 'Modified 16 Man Double Elimination 1-8')

    get :bracket, params: { id: @tournament.id, weight: @tournament.weights.first.id }

    assert_response :success
    assert_select '[role="tab"]', text: 'Placement Matches', count: 1
    assert_select '[id$="-panel-consolation"] .interactive-bracket__round h3', text: '5/6', count: 1
    assert_select '[id$="-panel-placement"] .interactive-bracket__round h3', text: '3/4', count: 1
    assert_select '[id$="-panel-placement"] .interactive-bracket__round h3', text: '7/8', count: 1
  end

  test 'pool bracket keeps pool tables without round navigation and fifth place with consolation' do
    sign_in_owner
    create_pool_tournament_single_weight(12)

    get :bracket, params: { id: @tournament.id, weight: @tournament.weights.first.id }

    assert_response :success
    assert_select '[role="tab"]', text: 'Pools', count: 1
    assert_select '[id$="-panel-pools"] table.table', count: 4
    assert_select '[id$="-panel-pools"] .interactive-bracket__navigator', count: 0
    assert_select '[id$="-panel-pools"] .interactive-bracket__viewport', count: 0
    assert_select '[id$="-panel-consolation"] .interactive-bracket__round h3', text: '5/6', count: 1
    assert_select '[id$="-panel-placement"] .interactive-bracket__round h3', text: '3/4', count: 1
  end

  test 'two pool semifinal bracket treats third place as consolation' do
    sign_in_owner
    create_pool_tournament_single_weight(8)

    get :bracket, params: { id: @tournament.id, weight: @tournament.weights.first.id }

    assert_response :success
    assert_select '[role="tab"]', text: 'Consolation Bracket', count: 1
    assert_select '[id$="-panel-consolation"] .interactive-bracket__round h3', text: '3/4', count: 1
    assert_select '[id$="-panel-placement"]', count: 0
  end

  test 'two pool final bracket shows pool and consolation paths' do
    sign_in_owner
    create_pool_tournament_single_weight(10)

    get :bracket, params: { id: @tournament.id, weight: @tournament.weights.first.id }

    assert_response :success
    assert_select '[role="tab"]', text: 'Pools', count: 1
    assert_select '[role="tab"]', text: 'Consolation Bracket', count: 1
    assert_select '[id$="-panel-championship"] .interactive-bracket__round h3', text: '1/2', count: 1
    assert_select '[id$="-panel-consolation"] .interactive-bracket__round h3', text: '3/4', count: 1
  end

  test 'one pool bracket renders its table without empty bracket tabs' do
    sign_in_owner
    create_pool_tournament_single_weight(5)

    get :bracket, params: { id: @tournament.id, weight: @tournament.weights.first.id }

    assert_response :success
    assert_select '[role="tab"]', text: 'Pools', count: 1
    assert_select '[role="tab"]', count: 1
    assert_select '[id$="-panel-pools"] table.table', count: 1
    assert_select '[id$="-panel-pools"] .interactive-bracket__navigator', count: 0
  end

  test 'eight pool bracket keeps every pool table' do
    sign_in_owner
    create_pool_tournament_single_weight(20)

    get :bracket, params: { id: @tournament.id, weight: @tournament.weights.first.id }

    assert_response :success
    assert_select '[id$="-panel-pools"] table.table', count: 8
    assert_select '[id$="-panel-pools"] h5', text: 'Pool 8', count: 1
    assert_select '[id$="-panel-pools"] .interactive-bracket__navigator', count: 0
  end

  test 'print bracket keeps the original layout' do
    sign_in_owner
    create_double_elim_tournament_single_weight(14, 'Regular Double Elimination 1-8')

    get :bracket, params: { id: @tournament.id, weight: @tournament.weights.first.id, print: true }

    assert_response :success
    assert_select '.interactive-bracket', count: 0
    assert_select '.bracket-container .game', minimum: 1
  end
end
