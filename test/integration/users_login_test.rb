# frozen_string_literal: true

require 'test_helper'

class UsersLoginTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    # Ensure password is set for the fixture user
    @user.password_digest = BCrypt::Password.create('password')
    @user.save
  end

  test 'login with invalid information' do
    get login_path
    assert_template 'sessions/new'
    post login_path, params: { session: { email: '', password: '' } }
    assert_response :unprocessable_content
    assert_template 'sessions/new'
    assert_not flash.empty?
    get root_path
    assert flash.empty?
  end

  test 'failed Turbo login renders an accessible error without persisting it' do
    post login_path,
         params: { session: { email: @user.email, password: 'wrong-password' } },
         headers: { 'Accept' => 'text/vnd.turbo-stream.html, text/html, application/xhtml+xml' }

    assert_response :unprocessable_content
    assert_nil session[:user_id]
    assert_select '#alert[role=alert]', text: %r{Invalid email/password combination}
    assert_select 'form[action=?] input[type=submit]', login_path

    get login_path
    assert_response :success
    assert_select '#alert', count: 0
  end

  test 'login with valid information followed by logout' do
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
