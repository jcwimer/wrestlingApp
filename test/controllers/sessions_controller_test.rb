require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
  def setup
    @user = users(:one)
    @user.email = 'user@example.com'
    @user.password_digest = BCrypt::Password.create('password')
    @user.save
  end

  test "should get new" do
    get :new
    assert_response :success
    assert_select 'h1', 'Log in'
  end

  test "should create session with valid credentials" do
    post :create, params: { session: { email: @user.email, password: 'password' } }
    assert_redirected_to root_path
    assert_equal @user.id, session[:user_id]
    assert_not_nil flash[:notice]
  end

  test "should not create session with invalid email" do
    post :create, params: { session: { email: 'wrong@example.com', password: 'password' } }
    assert_template 'new'
    assert_nil session[:user_id]
    assert_select 'div.alert'
  end

  test "should not create session with invalid password" do
    post :create, params: { session: { email: @user.email, password: 'wrongpassword' } }
    assert_template 'new'
    assert_nil session[:user_id]
    assert_select 'div.alert'
  end

  test "should destroy session" do
    session[:user_id] = @user.id
    delete :destroy
    assert_redirected_to root_path
    assert_nil session[:user_id]
    assert_not_nil flash[:notice]
  end

  test "should redirect to root after login" do
    target_url = edit_user_path(@user)
    session[:forwarding_url] = target_url
    post :create, params: { session: { email: @user.email, password: 'password' } }
    assert_redirected_to root_path
  end
end 