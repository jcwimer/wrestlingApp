module ApplicationHelper
  def hide_ads?
    return false unless controller_name == "schools"
    return false unless %w[show edit new].include?(action_name)

    user_signed_in? || school_permission_key_present?
  end

  def school_permission_key_present?
    @school_permission_key.present? ||
      params[:school_permission_key].present? ||
      params.dig(:school, :school_permission_key).present?
  end
end
