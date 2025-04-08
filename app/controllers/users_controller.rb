class UsersController < ApplicationController
  before_action :require_login, only: [:edit, :update]
  before_action :correct_user, only: [:edit, :update]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      session[:user_id] = @user.id
      redirect_to root_path, notice: "Account created successfully"
    else
      render 'new'
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      redirect_to root_path, notice: "Account updated successfully"
    else
      render 'edit'
    end
  end

  private
  
  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end

  def require_login
    unless current_user
      redirect_to login_path, alert: "Please log in to access this page"
    end
  end

  def correct_user
    @user = User.find(params[:id])
    redirect_to root_path unless current_user == @user
  end
end 