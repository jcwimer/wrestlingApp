require 'test_helper'

class PasswordResetsControllerTest < ActionController::TestCase
  def setup
    @user = users(:one)
    @user.email = 'user@example.com'
    @user.password_digest = BCrypt::Password.create('password')
    @user.save
    
    # Configure email for testing
    setup_test_mailer
  end

  test "should get new" do
    get :new
    assert_response :success
    assert_select 'h1', 'Forgot password'
    assert_select 'form[action=?]', password_resets_path
  end

  test "should not create password reset with invalid email" do
    post :create, params: { password_reset: { email: 'invalid@example.com' } }
    assert_template 'new'
    assert_not_nil flash[:alert]
  end
  
  test "should create password reset with valid email" do
    post :create, params: { password_reset: { email: @user.email } }
    assert_not_equal @user.reset_digest, @user.reload.reset_digest
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_not_nil flash[:notice]
    assert_redirected_to root_url
  end
  
  test "should get edit with valid token" do
    post :create, params: { password_reset: { email: @user.email } }
    user = assigns(:user)
    
    # Valid token, correct email
    get :edit, params: { id: user.reset_token, email: user.email }
    assert_response :success
    assert_select "input[name=?]", "user[password]"
    assert_select "input[name=?]", "user[password_confirmation]"
  end
  
  test "should update password with valid info" do
    post :create, params: { password_reset: { email: @user.email } }
    user = assigns(:user)
    
    # Valid token, correct email, valid info
    patch :update, params: { 
      id: user.reset_token,
      email: user.email,
      user: { 
        password: "newpassword",
        password_confirmation: "newpassword" 
      } 
    }
    
    assert_not_nil session[:user_id]
    assert_not_nil flash[:notice]
    assert_redirected_to root_url
  end
end 