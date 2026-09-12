# frozen_string_literal: true

class PasswordResetsController < ApplicationController
  before_action :load_user, only: %i[edit update]
  before_action :valid_user, only: %i[edit update]
  before_action :check_expiration, only: %i[edit update]

  def new; end

  def edit; end

  def create
    @user = User.find_by(email: params[:password_reset][:email].downcase)
    if @user
      @user.create_reset_digest
      @user.send_password_reset_email
      redirect_to root_url, notice: 'Email sent with password reset instructions'
    else
      flash.now[:alert] = 'Email address not found'
      render 'new'
    end
  end

  def update
    if params[:user][:password].empty?
      @user.errors.add(:password, "can't be empty")
      render 'edit'
    elsif @user.update(user_params)
      session[:user_id] = @user.id
      redirect_to root_url, notice: 'Password has been reset'
    else
      render 'edit'
    end
  end

  private

  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  def load_user
    @user = User.find_by(email: params[:email])
  end

  def valid_user
    return if @user&.authenticated?(:reset, params[:id])

    redirect_to root_url
  end

  def check_expiration
    return unless @user.password_reset_expired?

    redirect_to new_password_reset_url, alert: 'Password reset has expired'
  end
end
