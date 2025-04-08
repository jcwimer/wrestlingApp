require 'test_helper'

class PasswordResetsControllerTest < ActionController::TestCase
  def setup
    @user = users(:one)
    @user.email = 'user@example.com'
    @user.password_digest = BCrypt::Password.create('password')
    @user.save
  end

  test "should get new" do
    get :new
    assert_response :success
    assert_select 'h1', 'Forgot password'
  end

  test "should not create password reset with invalid email" do
    post :create, params: { password_reset: { email: 'invalid@example.com' } }
    assert_template 'new'
    assert_not_nil flash[:alert]
  end
end 