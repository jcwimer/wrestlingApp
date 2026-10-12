# frozen_string_literal: true

require 'test_helper'

class TournamentPostsControllerTest < ActionController::TestCase
  TOURNAMENT_VISIBILITY_STATES = [true, false].freeze

  setup do
    @tournament = tournaments(:one)
    @tournament_post = @tournament.tournament_posts.create!(title: 'Weigh-ins', body: 'Doors open at 7 AM.')
    @school = schools(:one)
    @school.update!(email: 'coach@example.com')
  end

  test 'managers can view all updates newest first with management controls but no school emails' do
    sign_in users(:one)
    @tournament_post.update!(is_public: false)
    newer = @tournament.tournament_posts.create!(title: 'Schedule', body: 'Wrestling starts at 9 AM.', is_public: true)

    get :index, params: { tournament_id: @tournament.id }

    assert_response :success
    assert_select 'article h2', text: 'Schedule'
    assert_operator response.body.index(newer.title), :<, response.body.index(@tournament_post.title)
    assert_select 'a', text: 'New Tournament Update'
    assert_select 'button', text: 'Email Coaches', count: 2
    assert_not_includes response.body, @school.email
  end

  test 'private tournament updates are available in the manager index' do
    @tournament.update!(is_public: false)
    sign_in users(:one)

    get :index, params: { tournament_id: @tournament.id }
    assert_response :success
    assert_includes response.body, @tournament_post.body
  end

  test 'anonymous visitors cannot view update management index for public or private tournaments' do
    [true, false].each do |is_public|
      @tournament.update!(is_public: is_public)
      get :index, params: { tournament_id: @tournament.id }
      assert_redirected_to '/static_pages/not_allowed'
    end
  end

  %i[one three].each do |user|
    test "#{user} can publish an update and email only schools in this tournament with emails" do
      sign_in users(user)
      tournaments(:two).schools.create!(name: 'Other school', email: 'other@example.com')
      assert_difference 'TournamentPost.count' do
        assert_enqueued_jobs 1, only: EmailTournamentPostJob do
          post :create, params: { tournament_id: @tournament.id, email_coaches: '1',
                                  tournament_post: { title: 'Lunch', body: 'Lunch is available in the cafeteria.' } }
        end
      end

      queued = enqueued_jobs.select { |job| job[:job] == EmailTournamentPostJob }
      assert_equal [[@tournament.tournament_posts.order(:id).last.id, @school.id]], queued.pluck(:args)
      assert_not @tournament.tournament_posts.order(:id).last.is_public
      assert_redirected_to tournament_tournament_posts_path(@tournament)
      assert_includes flash[:notice], 'Emails queued for 1 school.'
    end
  end

  %i[two four].each do |user|
    test "#{user} cannot publish or email updates" do
      sign_in users(user)
      TOURNAMENT_VISIBILITY_STATES.each do |is_public|
        @tournament.update!(is_public: is_public)
        get :index, params: { tournament_id: @tournament.id }
        assert_redirected_to '/static_pages/not_allowed'
      end
      assert_no_difference 'TournamentPost.count' do
        assert_no_enqueued_jobs only: EmailTournamentPostJob do
          post :create, params: { tournament_id: @tournament.id, email_coaches: '1',
                                  tournament_post: { title: 'Unauthorized', body: 'Update' } }
          assert_redirected_to '/static_pages/not_allowed'
          post :email_coaches, params: { tournament_id: @tournament.id, id: @tournament_post.id }
          assert_redirected_to '/static_pages/not_allowed'
        end
      end
    end
  end

  test 'anonymous visitors cannot publish or email updates' do
    TOURNAMENT_VISIBILITY_STATES.each do |is_public|
      @tournament.update!(is_public: is_public)
      get :index, params: { tournament_id: @tournament.id }
      assert_redirected_to '/static_pages/not_allowed'
    end

    assert_no_difference 'TournamentPost.count' do
      assert_no_enqueued_jobs only: EmailTournamentPostJob do
        post :create, params: { tournament_id: @tournament.id, tournament_post: { title: 'No', body: 'No' } }
        assert_redirected_to '/static_pages/not_allowed'
        post :email_coaches, params: { tournament_id: @tournament.id, id: @tournament_post.id }
        assert_redirected_to '/static_pages/not_allowed'
      end
    end
  end

  test 'saving without the email checkbox publishes without enqueueing email' do
    sign_in users(:one)
    get :new, params: { tournament_id: @tournament.id }
    assert_response :success
    assert_select 'input[name=email_coaches][checked]', count: 0
    assert_select 'label[for=tournament_post_is_public]', text: 'Is a public update'

    assert_no_enqueued_jobs only: EmailTournamentPostJob do
      post :create, params: { tournament_id: @tournament.id,
                              tournament_post: { title: 'Parking', body: 'Use lot B.', is_public: '1' } }
    end
    saved_post = @tournament.tournament_posts.order(:id).last
    assert_equal 'Parking', saved_post.title
    assert saved_post.is_public
  end

  test 'public update visibility can be created and toggled by managers' do
    sign_in users(:one)
    post :create, params: { tournament_id: @tournament.id,
                            tournament_post: { title: 'Parking', body: 'Use lot B.', is_public: '1' } }
    saved_post = @tournament.tournament_posts.order(:id).last
    assert saved_post.is_public

    patch :update, params: { tournament_id: @tournament.id, id: saved_post.id,
                             tournament_post: { is_public: '0' } }
    assert_not saved_post.reload.is_public

    patch :update, params: { tournament_id: @tournament.id, id: saved_post.id,
                             tournament_post: { is_public: '1' } }
    assert saved_post.reload.is_public
  end

  test 'invalid updates show errors and do not email coaches' do
    sign_in users(:one)
    assert_no_difference 'TournamentPost.count' do
      assert_no_enqueued_jobs only: EmailTournamentPostJob do
        post :create, params: { tournament_id: @tournament.id, email_coaches: '1', tournament_post: { title: '', body: '' } }
      end
    end
    assert_response :unprocessable_content
    assert_select '.alert', text: /Title can't be blank/
    assert_select 'input[name=email_coaches][checked]'
  end

  test 'director can edit an update and optionally email the changes' do
    sign_in users(:one)
    get :edit, params: { tournament_id: @tournament.id, id: @tournament_post.id }
    assert_response :success

    assert_enqueued_with(job: EmailTournamentPostJob, args: [@tournament_post.id, @school.id]) do
      patch :update, params: { tournament_id: @tournament.id, id: @tournament_post.id, email_coaches: '1',
                               tournament_post: { body: 'Doors open at 8 AM.' } }
    end
    assert_equal 'Doors open at 8 AM.', @tournament_post.reload.body
  end

  test 'invalid edit preserves the saved update' do
    sign_in users(:one)
    patch :update, params: { tournament_id: @tournament.id, id: @tournament_post.id, tournament_post: { body: '' } }
    assert_response :unprocessable_content
    assert_equal 'Doors open at 7 AM.', @tournament_post.reload.body
  end

  test 'director can email an existing post or get a clear notice when no recipients exist' do
    sign_in users(:one)
    assert_enqueued_with(job: EmailTournamentPostJob, args: [@tournament_post.id, @school.id]) do
      post :email_coaches, params: { tournament_id: @tournament.id, id: @tournament_post.id }
    end

    @school.update!(email: nil)
    assert_no_enqueued_jobs only: EmailTournamentPostJob do
      post :email_coaches, params: { tournament_id: @tournament.id, id: @tournament_post.id }
    end
    assert_includes flash[:notice], 'No emails queued'
  end

  test 'posts cannot be managed through a different tournament' do
    sign_in users(:one)
    assert_raises ActiveRecord::RecordNotFound do
      post :email_coaches, params: { tournament_id: tournaments(:two).id, id: @tournament_post.id }
    end
    assert_raises ActiveRecord::RecordNotFound do
      patch :update, params: { tournament_id: tournaments(:two).id, id: @tournament_post.id, tournament_post: { title: 'No' } }
    end
  end

  test 'tournament delegate can delete a post' do
    sign_in users(:three)
    assert_difference 'TournamentPost.count', -1 do
      delete :destroy, params: { tournament_id: @tournament.id, id: @tournament_post.id }
    end
    assert_redirected_to tournament_tournament_posts_path(@tournament)
  end

  test 'school delegates cannot edit or delete tournament posts' do
    sign_in users(:four)
    patch :update, params: { tournament_id: @tournament.id, id: @tournament_post.id, tournament_post: { title: 'No' } }
    assert_redirected_to '/static_pages/not_allowed'
    assert_equal 'Weigh-ins', @tournament_post.reload.title
    assert_no_difference 'TournamentPost.count' do
      delete :destroy, params: { tournament_id: @tournament.id, id: @tournament_post.id }
    end
    assert_redirected_to '/static_pages/not_allowed'
  end
end
