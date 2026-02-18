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

  test "get root page" do
    get :home
    success
  end

  test "get my_tournaments" do
    sign_in_owner
    get :my_tournaments  
    success
  end

  test "my_tournaments page lists delegated tournament and delegated school once in html" do
    user = users(:two)
    sign_in_non_owner

    delegated_tournament = Tournament.create!(
      name: "Delegated Tournament #{SecureRandom.hex(4)}",
      address: "123 Delegate St",
      director: "Director",
      director_email: "delegate_tournament_#{SecureRandom.hex(4)}@example.com",
      tournament_type: "Pool to bracket",
      date: Date.today,
      is_public: true
    )
    TournamentDelegate.create!(tournament_id: delegated_tournament.id, user_id: user.id)

    school_tournament = Tournament.create!(
      name: "School Tournament #{SecureRandom.hex(4)}",
      address: "456 School St",
      director: "Director",
      director_email: "delegate_school_#{SecureRandom.hex(4)}@example.com",
      tournament_type: "Pool to bracket",
      date: Date.today + 1,
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
