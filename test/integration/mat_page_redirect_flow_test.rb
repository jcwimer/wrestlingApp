# frozen_string_literal: true

require 'test_helper'

class MatPageRedirectFlowTest < ActionDispatch::IntegrationTest
  fixtures :all

  setup do
    @tournament = tournaments(:one)
    @mat = mats(:one)
    @queue1_match = matches(:tournament_1_bout_1000)
    @queue2_match = matches(:tournament_1_bout_1001)
    @owner = users(:one)
    @mat.update!(queue1: @queue1_match.id, queue2: @queue2_match.id, queue3: nil, queue4: nil)
    @queue1_match.update_columns(mat_id: @mat.id, finalized_at: nil, finished: nil, winner_id: nil, win_type: nil, score: nil)
    @queue2_match.update_columns(mat_id: @mat.id, finalized_at: nil)
    ensure_login_password(@owner)
    ActiveJob::Base.queue_adapter = :test
  end

  teardown do
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear if ActiveJob::Base.queue_adapter.respond_to?(:enqueued_jobs)
    ActiveJob::Base.queue_adapter = :inline
  end

  test 'tournament show links stat match to mat stat page' do
    log_in(@owner)

    get tournament_path(@tournament)

    assert_response :success
    assert_includes response.body, stat_mat_path(@mat)
    assert_not_includes response.body, stat_match_path(@queue1_match)
  end

  test 'mat stat page sets redirect path back to mat stat' do
    log_in(@owner)

    get stat_mat_path(@mat)

    assert_response :success
    assert_includes response.body, "value=\"#{stat_mat_path(@mat)}\""
  end

  test 'mat state update redirects back to mat state and shows next queued match immediately' do
    log_in(@owner)

    get state_mat_path(@mat, bout_number: @queue1_match.bout_number)
    assert_response :success

    assert_enqueued_with(job: AdvanceWrestlerJob) do
      assert_enqueued_with(job: FillBoutBoardJob) do
        patch match_path(@queue1_match), params: {
          match: {
            score: '3-1',
            win_type: 'Decision',
            winner_id: @queue1_match.w1,
            finished: 1
          }
        }
      end
    end

    assert_redirected_to state_mat_path(@mat)
    follow_redirect!

    assert_response :success
    assert_equal @queue2_match.id, @mat.reload.queue1
    assert_includes response.body, "data-match-state-match-id-value=\"#{@queue2_match.id}\""
    assert_not_includes response.body, "data-match-state-match-id-value=\"#{@queue1_match.id}\""
  end

  test 'mat stat update redirects back to mat stat and shows next queued match immediately' do
    log_in(@owner)

    get stat_mat_path(@mat, bout_number: @queue1_match.bout_number)
    assert_response :success

    assert_enqueued_with(job: AdvanceWrestlerJob) do
      assert_enqueued_with(job: FillBoutBoardJob) do
        patch match_path(@queue1_match), params: {
          match: {
            score: '3-1',
            win_type: 'Decision',
            winner_id: @queue1_match.w1,
            finished: 1
          }
        }
      end
    end

    assert_redirected_to stat_mat_path(@mat)
    follow_redirect!

    assert_response :success
    assert_equal @queue2_match.id, @mat.reload.queue1
    assert_includes response.body, "Bout <strong>#{@queue2_match.bout_number}</strong>"
    assert_not_includes response.body, "data-match-data-match-id-value=\"#{@queue1_match.id}\""
  end

  test 'mat show still redirects match updates back to mat show' do
    log_in(@owner)

    get mat_path(@mat, bout_number: @queue1_match.bout_number)
    assert_response :success

    patch match_path(@queue1_match), params: {
      match: {
        score: '3-1',
        win_type: 'Decision',
        winner_id: @queue1_match.w1,
        finished: 1
      }
    }

    assert_redirected_to mat_path(@mat)
    follow_redirect!

    assert_response :success
    assert_equal @queue2_match.id, @mat.reload.queue1
    assert_includes response.body, "Bout <strong>#{@queue2_match.bout_number}</strong>"
  end

  private

  def ensure_login_password(user)
    return if user.password_digest.present?

    user.update_column(:password_digest, BCrypt::Password.create('password'))
  end

  def log_in(user)
    post login_path, params: {
      session: {
        email: user.email,
        password: 'password'
      }
    }
  end
end
