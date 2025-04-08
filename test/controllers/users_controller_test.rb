require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  def setup
    @user = users(:one)
    @user.password_digest = BCrypt::Password.create('password')
    @user.save
    
    @other_user = users(:two)
    @other_user.password_digest = BCrypt::Password.create('password')
    @other_user.save
  end

  test "should get new" do
    get :new
    assert_response :success
    assert_template 'users/new'
  end

  test "should create user with valid information" do
    assert_difference('User.count') do
      post :create, params: { user: { email: "test@example.com", 
                                     password: "password", password_confirmation: "password" } }
    end
    assert_redirected_to root_path
    assert_not_nil session[:user_id]
  end

  test "should not create user with invalid information" do
    assert_no_difference('User.count') do
      post :create, params: { user: { email: "invalid", 
                                     password: "pass", password_confirmation: "word" } }
    end
    assert_template 'new'
  end

  test "should get edit when logged in" do
    sign_in(@user)
    get :edit, params: { id: @user.id }
    assert_response :success
    assert_template 'users/edit'
  end

  test "should redirect edit when not logged in" do
    get :edit, params: { id: @user.id }
    assert_redirected_to login_path
  end

  test "should redirect edit when logged in as wrong user" do
    sign_in(@other_user)
    get :edit, params: { id: @user.id }
    assert_redirected_to root_path
  end

  test "should update user with valid information" do
    sign_in(@user)
    patch :update, params: { id: @user.id, user: { 
                                                  password: "newpassword", 
                                                  password_confirmation: "newpassword" } }
    assert_redirected_to root_path
    @user.reload
  end

  test "should not update user with invalid information" do
    sign_in(@user)
    patch :update, params: { id: @user.id, user: { 
                                                  password: "new", 
                                                  password_confirmation: "password" } }
    assert_template 'edit'
  end

  test "should redirect update when not logged in" do
    patch :update, params: { id: @user.id, user: { email: "new@example.com" } }
    assert_redirected_to login_path
  end

  test "should redirect update when logged in as wrong user" do
    sign_in(@other_user)
    patch :update, params: { id: @user.id, user: { email: "new@example.com" } }
    assert_redirected_to root_path
  end
end 