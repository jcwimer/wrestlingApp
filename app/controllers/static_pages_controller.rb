# frozen_string_literal: true

class StaticPagesController < ApplicationController
  def my_tournaments
    tournament_ids = current_user.tournament_ids + current_user.delegated_tournaments.pluck(:id)
    @tournaments = Tournament.includes(:delegates).where(id: tournament_ids).sort_by(&:days_until_start)
    @schools = current_user.delegated_schools.includes(:tournament)
  end

  def not_allowed; end

  def about; end

  def tutorials; end
end
