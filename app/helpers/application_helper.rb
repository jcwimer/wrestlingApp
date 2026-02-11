module ApplicationHelper
  def hide_ads?
    case controller_name
    when "schools"
      action_name == "show" && (user_signed_in? || school_permission_key_present?)
    when "wrestlers"
      %w[new edit].include?(action_name) && (user_signed_in? || school_permission_key_present?)
    when "mats"
      action_name == "show" && user_signed_in?
    else
      false
    end
  end

  def school_permission_key_present?
    @school_permission_key.present? ||
      params[:school_permission_key].present? ||
      params.dig(:school, :school_permission_key).present?
  end
end
