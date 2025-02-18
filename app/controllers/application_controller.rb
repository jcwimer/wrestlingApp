class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery prepend: true, with: :exception

  after_action :set_csrf_cookie_for_ng
  
  def set_csrf_cookie_for_ng
    cookies['XSRF-TOKEN'] = form_authenticity_token if protect_against_forgery?
  end
  
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to '/static_pages/not_allowed'
  end

  protected

  # In Rails 4.2 and above
  def verified_request?
    super || valid_authenticity_token?(session, request.headers['X-XSRF-TOKEN'])
  end

  # Override current_ability to pass school_permission_key
  # @school_permission_key needs to be defined on the controller
  def current_ability
    @current_ability ||= Ability.new(current_user, @school_permission_key)
  end
end
