# frozen_string_literal: true

require 'test_helper'

class StaticPagesControllerTest < ActionController::TestCase
  # Remove Devise helpers since we're no longer using Devise
  # include Devise::Test::ControllerHelpers

  setup do
    @tournament = Tournament.find(1)
    # @tournament.generateMatchups
    @school = @tournament.schools.first
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

  test 'get root page' do
    get :home
    success
  end

  test 'about page describes current tournament features without signing in' do
    get :about

    assert_response :success
    assert_select 'h2', 'About WrestlingDev'
    assert_select 'section#tournament-management' do
      assert_select 'h3', text: 'Tournament Management', count: 1
      assert_select 'h4', count: 5
      assert_select 'h5', count: 5
      assert_select 'li', text: /season records/, count: 0
    end
    assert_select 'section#tournament-management h3', text: 'Contact', count: 0
    assert_select 'h3', 'Contact'
    assert_select 'li', text: /full-screen scoreboards/
    assert_select 'li', text: /Create and restore tournament backups/
    assert_select 'li', text: /Two Pools of 5.*9-10 wrestlers/
    assert_select 'li', text: /Four pools of 3.*11-12 wrestlers/
    assert_select 'h3', text: 'Future Plans', count: 0
    assert_select 'div.tw\\:overflow-x-auto table tbody tr', count: 3
  end

  test 'get my_tournaments' do
    sign_in_owner
    get :my_tournaments
    success
  end

  test 'my_tournaments page lists delegated tournament and delegated school once in html' do
    user = users(:two)
    sign_in_non_owner

    delegated_tournament = Tournament.create!(
      name: "Delegated Tournament #{SecureRandom.hex(4)}",
      address: '123 Delegate St',
      director: 'Director',
      director_email: "delegate_tournament_#{SecureRandom.hex(4)}@example.com",
      tournament_type: 'Pool to bracket',
      date: Time.zone.today,
      is_public: true
    )
    TournamentDelegate.create!(tournament_id: delegated_tournament.id, user_id: user.id)

    school_tournament = Tournament.create!(
      name: "School Tournament #{SecureRandom.hex(4)}",
      address: '456 School St',
      director: 'Director',
      director_email: "delegate_school_#{SecureRandom.hex(4)}@example.com",
      tournament_type: 'Pool to bracket',
      date: Time.zone.today + 1,
      is_public: true
    )
    delegated_school = School.create!(
      name: "Delegated School #{SecureRandom.hex(4)}",
      tournament_id: school_tournament.id
    )
    SchoolDelegate.create!(school_id: delegated_school.id, user_id: user.id)

    get :my_tournaments
    assert_response :success
    assert_equal 1, response.body.scan(delegated_tournament.name).size
    assert_equal 1, response.body.scan(delegated_school.name).size
    assert_equal 1, response.body.scan(school_tournament.name).size
  end
end
