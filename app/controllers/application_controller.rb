# frozen_string_literal: true

class ApplicationController < ActionController::Base
  around_action :detect_n_plus_one_queries unless Rails.env.production?

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery prepend: true, with: :exception

  # Add helpers for authentication (replacing Devise)
  helper_method :current_user, :user_signed_in?

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def user_signed_in?
    current_user.present?
  end

  def authenticate_user!
    redirect_to login_path, alert: 'Please log in to access this page' unless user_signed_in?
  end

  rescue_from CanCan::AccessDenied do |_exception|
    redirect_to '/static_pages/not_allowed'
  end

  protected

  def detect_n_plus_one_queries(&)
    Prosopite.scan(&)
  end

  # Override current_ability to pass school_permission_key
  # @school_permission_key needs to be defined on the controller
  def current_ability
    @current_ability ||= Ability.new(current_user, @school_permission_key)
  end
end
