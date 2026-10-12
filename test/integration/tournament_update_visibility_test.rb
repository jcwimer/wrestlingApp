# frozen_string_literal: true

require 'test_helper'

class TournamentUpdateVisibilityTest < ActionDispatch::IntegrationTest
  fixtures :all
  TOURNAMENT_VISIBILITY_STATES = [true, false].freeze

  setup do
    @tournament = tournaments(:one)
    @public_post = @tournament.tournament_posts.create!(
      title: 'Public update marker', body: 'Visible public update body.', is_public: true
    )
    @private_post = @tournament.tournament_posts.create!(
      title: 'Private update marker', body: 'Hidden coaches-only body.', is_public: false
    )
  end

  [
    ['anonymous guest', nil],
    ['signed-in user', :two],
    ['tournament owner', :one]
  ].each do |actor, user_key|
    TOURNAMENT_VISIBILITY_STATES.each do |tournament_is_public|
      test "#{actor} sees only public updates when tournament visibility is #{tournament_is_public}" do
        @tournament.update!(is_public: tournament_is_public)
        log_in(users(user_key)) if user_key

        get tournament_path(@tournament)

        assert_response :success
        assert_select '#tournament-updates article', count: 1
        assert_includes response.body, @public_post.title
        assert_includes response.body, @public_post.body
        assert_not_includes response.body, @private_post.title
        assert_not_includes response.body, @private_post.body
        assert_operator response.body.index('id="tournament-updates"'), :<,
                        response.body.index('id="tournament-schools"')
        assert_select 'a[href=?]', tournament_tournament_posts_path(@tournament), count: 0
        assert_select '#tournament-updates a[href=?]', tournament_tournament_posts_path(@tournament), count: 0
        assert_select '#tournament-updates a', text: 'Edit', count: 0
        assert_select '#tournament-updates button', count: 0
      end
    end
  end

  test 'director links expose update management to the owner and tournament delegate' do
    assert_director_link_for(users(:one))
    delete logout_path
    assert_director_link_for(users(:three))
  end

  private

  def log_in(user)
    user.update_column(:password_digest, BCrypt::Password.create('password')) if user.password_digest.blank?
    post login_path, params: { session: { email: user.email, password: 'password' } }
  end

  def assert_director_link_for(user)
    log_in(user)
    get director_tournament_path(@tournament)

    assert_response :success
    assert_select 'a[href=?]', tournament_tournament_posts_path(@tournament), text: 'Tournament Updates'
  end
end
