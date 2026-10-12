# frozen_string_literal: true

require 'test_helper'

class EmailTournamentPostJobTest < ActiveJob::TestCase
  setup do
    @tournament_post = tournaments(:one).tournament_posts.create!(title: 'Schedule', body: 'Start at 9 AM.')
    @school = schools(:one)
    @school.update!(email: 'coach@example.com')
    ActionMailer::Base.deliveries.clear
  end

  test 'delivers the post to an individual school' do
    EmailTournamentPostJob.perform_now(@tournament_post.id, @school.id)

    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal ['coach@example.com'], ActionMailer::Base.deliveries.last.to
    assert_includes ActionMailer::Base.deliveries.last.text_part.decoded, @tournament_post.body
    assert_includes ActionMailer::Base.deliveries.last.html_part.decoded, @tournament_post.body
    assert_includes ActionMailer::Base.deliveries.last.text_part.decoded, @tournament_post.title
    assert_includes ActionMailer::Base.deliveries.last.html_part.decoded, @tournament_post.title
    assert_no_match(%r{https?://|/tournaments/}, ActionMailer::Base.deliveries.last.text_part.decoded)
    assert_no_match(%r{https?://|/tournaments/}, ActionMailer::Base.deliveries.last.html_part.decoded)
  end

  test 'skips a school whose email has been removed' do
    @school.update!(email: '')
    EmailTournamentPostJob.perform_now(@tournament_post.id, @school.id)
    assert_empty ActionMailer::Base.deliveries
  end

  test 'skips a school from another tournament' do
    @school.update!(tournament: tournaments(:two))
    EmailTournamentPostJob.perform_now(@tournament_post.id, @school.id)
    assert_empty ActionMailer::Base.deliveries
  end

  test 'skips a deleted post' do
    @tournament_post.destroy!
    EmailTournamentPostJob.perform_now(@tournament_post.id, @school.id)
    assert_empty ActionMailer::Base.deliveries
  end

  test 'skips a deleted school' do
    @school.destroy_with_dependents!
    EmailTournamentPostJob.perform_now(@tournament_post.id, @school.id)
    assert_empty ActionMailer::Base.deliveries
  end
end
