# frozen_string_literal: true

class EmailTournamentPostJob < ApplicationJob
  queue_as :default

  def perform(tournament_post_id, school_id)
    tournament_post = TournamentPost.find_by(id: tournament_post_id)
    return unless tournament_post

    school = tournament_post.tournament.schools.find_by(id: school_id)
    return if school&.email.blank?

    TournamentPostMailer.update_post(tournament_post, school).deliver_now
  end
end
