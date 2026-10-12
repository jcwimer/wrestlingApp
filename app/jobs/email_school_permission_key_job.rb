# frozen_string_literal: true

class EmailSchoolPermissionKeyJob < ApplicationJob
  self.log_arguments = false

  queue_as :default

  def perform(school_id, expected_permission_key, base_url)
    school = School.find_by(id: school_id)
    return unless school&.email.present? && expected_permission_key.present? &&
                  school.permission_key == expected_permission_key

    SchoolMailer.permission_key(school, base_url).deliver_now
  end
end
