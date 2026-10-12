# frozen_string_literal: true

require 'test_helper'

class EmailSchoolPermissionKeyJobTest < ActiveJob::TestCase
  setup do
    @school = schools(:one)
    @school.update!(email: 'coach@example.com', permission_key: 'current-key')
    @base_url = 'https://test.wrestlingdev.com:8443'
    ActionMailer::Base.deliveries.clear
  end

  test 'sends the current permission link to the school email' do
    EmailSchoolPermissionKeyJob.perform_now(@school.id, 'current-key', @base_url)

    message = ActionMailer::Base.deliveries.last
    assert_equal ['coach@example.com'], message.to
    expected_url = @base_url + Rails.application.routes.url_helpers.school_path(
      @school,
      school_permission_key: 'current-key'
    )
    assert_includes message.text_part.decoded, expected_url
    assert_includes message.html_part.decoded, expected_url
  end

  test 'does not send when the key has changed' do
    EmailSchoolPermissionKeyJob.perform_now(@school.id, 'old-key', @base_url)

    assert_empty ActionMailer::Base.deliveries
  end

  test 'does not send when the school email was removed' do
    @school.update!(email: nil)

    EmailSchoolPermissionKeyJob.perform_now(@school.id, 'current-key', @base_url)

    assert_empty ActionMailer::Base.deliveries
  end

  test 'does not send when the school no longer exists' do
    school_id = @school.id
    @school.destroy!

    EmailSchoolPermissionKeyJob.perform_now(school_id, 'current-key', @base_url)

    assert_empty ActionMailer::Base.deliveries
  end
end
