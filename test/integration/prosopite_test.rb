# frozen_string_literal: true

require 'test_helper'

class ProsopiteTest < ActiveSupport::TestCase
  setup do
    @wrestlers = Wrestler.order(:id).limit(3).to_a
  end

  test 'explicit batched preloading of both match associations is not an N+1' do
    notifications = Prosopite.n_plus_one_queries do
      ActiveRecord::Associations::Preloader.new(
        records: @wrestlers,
        associations: %i[matches_as_w1 matches_as_w2]
      ).call
    end

    assert_empty notifications
    @wrestlers.each do |wrestler|
      assert_predicate wrestler.association(:matches_as_w1), :loaded?
      assert_predicate wrestler.association(:matches_as_w2), :loaded?
    end
  end

  test 'lazy loading match associations still raises for an N+1' do
    assert_raises Prosopite::NPlusOneQueriesError do
      Prosopite.scan do
        @wrestlers.each { |wrestler| wrestler.matches_as_w1.to_a }
      end
    end
  end
end
