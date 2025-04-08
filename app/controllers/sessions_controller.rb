class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:session][:email].downcase)
    if user && user.authenticate(params[:session][:password])
      session[:user_id] = user.id
      redirect_to root_path, notice: "Logged in successfully"
    else
      flash.now[:alert] = "Invalid email/password combination"
      render 'new'
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to root_path, notice: "Logged out successfully"
  end
end 