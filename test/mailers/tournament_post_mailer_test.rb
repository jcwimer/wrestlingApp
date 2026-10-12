# frozen_string_literal: true

require 'test_helper'

class TournamentPostMailerTest < ActionMailer::TestCase
  test 'email contains the update without other recipients or unsafe HTML' do
    school = schools(:one)
    school.update!(email: 'coach@example.com')
    tournament = school.tournament
    tournament_post = tournament.tournament_posts.create!(title: 'Schedule', body: "Start at 9 AM.\n<script>alert('bad')</script>")

    email = TournamentPostMailer.update_post(tournament_post, school)

    assert_equal ['coach@example.com'], email.to
    assert_nil email.cc
    assert_nil email.bcc
    assert_equal "#{tournament.name}: Schedule", email.subject
    assert_includes email.text_part.decoded, tournament_post.body
    assert_includes email.text_part.decoded, tournament_post.title
    assert_includes email.html_part.decoded, tournament_post.title
    assert_includes email.html_part.decoded, 'Start at 9 AM.'
    assert_includes email.html_part.decoded, "alert('bad')"
    assert_includes email.html_part.decoded, school.name
    assert_not_includes email.html_part.decoded, '<script>'
    assert_no_match(%r{https?://|/tournaments/}, email.text_part.decoded)
    assert_no_match(%r{https?://|/tournaments/}, email.html_part.decoded)
  end
end
