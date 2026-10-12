# frozen_string_literal: true

require 'test_helper'

class TournamentPostTest < ActiveSupport::TestCase
  test 'requires a tournament and nonblank title and body' do
    tournament_post = TournamentPost.new(title: ' ', body: '')
    assert_not tournament_post.valid?
    assert tournament_post.errors.added?(:tournament, :blank)
    assert tournament_post.errors.added?(:title, :blank)
    assert tournament_post.errors.added?(:body, :blank)
  end

  test 'rejects titles too long for the database column' do
    tournament_post = tournaments(:one).tournament_posts.build(title: 'x' * 256, body: 'Update')
    assert_not tournament_post.valid?
    assert tournament_post.errors.of_kind?(:title, :too_long)
  end

  test 'defaults to private' do
    tournament_post = tournaments(:one).tournament_posts.build(title: 'Update', body: 'Details')

    assert_not_predicate tournament_post, :is_public?
  end
end
