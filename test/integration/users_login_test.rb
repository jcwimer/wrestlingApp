require "test_helper"

class UsersLoginTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    # Ensure password is set for the fixture user
    @user.password_digest = BCrypt::Password.create('password')
    @user.save
  end

  test "login with invalid information" do
    get login_path
    assert_template 'sessions/new'
    post login_path, params: { session: { email: "", password: "" } }
    assert_template 'sessions/new'
    assert_not flash.empty?
    get root_path
    assert flash.empty?
  end

  test "login with valid information followed by logout" do
    get login_path
    post login_path, params: { session: { email: @user.email,
                                          password: 'password' } }
    assert session[:user_id].present?
    assert_redirected_to root_path
    follow_redirect!
    assert_template 'static_pages/home'
    
    # Verify logout
    delete logout_path
    assert_nil session[:user_id]
    assert_redirected_to root_path
    follow_redirect!
    assert_template 'static_pages/home'
  end

  # test "the truth" do
  #   assert true
  # end
end
