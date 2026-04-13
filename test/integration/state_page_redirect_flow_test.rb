require "test_helper"

class StatePageRedirectFlowTest < ActionDispatch::IntegrationTest
  fixtures :all

  setup do
    @tournament = tournaments(:one)
    @mat = mats(:one)
    @match = matches(:tournament_1_bout_1000)
    @owner = users(:one)
    ensure_login_password(@owner)
  end

  test "match state update redirects to all matches by default" do
    log_in(@owner)

    get state_match_path(@match)
    assert_response :success

    patch match_path(@match), params: {
      match: {
        score: "3-1",
        win_type: "Decision",
        winner_id: @match.w1,
        finished: 1
      }
    }

    assert_redirected_to "/tournaments/#{@tournament.id}/matches"
  end

  test "match state update respects redirect_to param through request flow" do
    log_in(@owner)

    get state_match_path(@match), params: { redirect_to: mat_path(@mat) }
    assert_response :success

    patch match_path(@match), params: {
      redirect_to: mat_path(@mat),
      match: {
        score: "3-1",
        win_type: "Decision",
        winner_id: @match.w1,
        finished: 1
      }
    }

    assert_redirected_to mat_path(@mat)
  end

  test "mat state update redirects back to mat state through request flow" do
    log_in(@owner)

    get state_mat_path(@mat), params: { bout_number: @match.bout_number }
    assert_response :success

    patch match_path(@match), params: {
      match: {
        score: "3-1",
        win_type: "Decision",
        winner_id: @match.w1,
        finished: 1
      }
    }

    assert_redirected_to state_mat_path(@mat)
  end

  private

  def ensure_login_password(user)
    return if user.password_digest.present?

    user.update_column(:password_digest, BCrypt::Password.create("password"))
  end

  def log_in(user)
    post login_path, params: {
      session: {
        email: user.email,
        password: "password"
      }
    }
  end
end
