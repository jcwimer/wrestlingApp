# frozen_string_literal: true

class TournamentPostMailer < ApplicationMailer
  def update_post(tournament_post, school)
    @tournament_post = tournament_post
    @tournament = tournament_post.tournament
    @school = school
    mail to: school.email, subject: "#{@tournament.name}: #{tournament_post.title}"
  end
end
