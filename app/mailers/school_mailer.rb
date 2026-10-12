# frozen_string_literal: true

class SchoolMailer < ApplicationMailer
  def permission_key(school, base_url)
    @school = school
    @tournament = school.tournament
    @url = "#{base_url}#{Rails.application.routes.url_helpers.school_path(school, school_permission_key: school.permission_key)}"

    mail to: school.email, subject: "#{@tournament.name} school lineup link"
  end
end
