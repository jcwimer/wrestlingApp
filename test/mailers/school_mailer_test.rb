# frozen_string_literal: true

require 'test_helper'

class SchoolMailerTest < ActionMailer::TestCase
  test 'permission key email includes the school link and tournament' do
    school = schools(:one)
    school.update!(email: 'coach@example.com', permission_key: 'school-key')
    base_url = 'https://test.wrestlingdev.com:8443'

    email = SchoolMailer.permission_key(school, base_url)

    assert_equal ['coach@example.com'], email.to
    assert_equal "#{school.tournament.name} school lineup link", email.subject
    assert_includes email.body.encoded, school.name
    assert_includes email.body.encoded, school.tournament.name
    expected_url = base_url + Rails.application.routes.url_helpers.school_path(
      school,
      school_permission_key: 'school-key'
    )
    assert_includes email.text_part.decoded, expected_url
    assert_includes email.html_part.decoded, expected_url
  end
end
