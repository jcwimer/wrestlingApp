module ApplicationHelper
  def tournament_permissions(tournament)
    if user_signed_in?
      if tournament.user == current_user
	return true
      else
	return false
      end
    else
      return false
    end
  end

end
