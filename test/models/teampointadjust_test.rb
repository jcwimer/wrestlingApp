# frozen_string_literal: true

require 'test_helper'

class TeampointadjustTest < ActiveSupport::TestCase
  test 'wrestler caches remain available until the adjustment commits' do
    wrestler = wrestlers(:tournament_1_wrestler_1)
    profile_key = ApplicationController.new.combined_fragment_cache_key(
      TournamentCacheInvalidator.wrestler_profile_key(wrestler.id)
    )
    roster_key = ApplicationController.new.combined_fragment_cache_key(
      TournamentCacheInvalidator.school_roster_key(wrestler.school_id)
    )
    Rails.cache.write_multi(profile_key => 'cached', roster_key => 'cached')

    Teampointadjust.transaction do
      Teampointadjust.create!(wrestler: wrestler, points: 1)
      assert Rails.cache.exist?(profile_key)
      assert Rails.cache.exist?(roster_key)
    end

    assert_not Rails.cache.exist?(profile_key)
    assert_not Rails.cache.exist?(roster_key)
  ensure
    Rails.cache.clear
  end

  test 'school summary remains available until the adjustment commits' do
    school = schools(:one)
    summary_key = ApplicationController.new.combined_fragment_cache_key(
      TournamentCacheInvalidator.school_summary_key(school.id)
    )
    Rails.cache.write(summary_key, 'cached')

    perform_enqueued_jobs do
      Teampointadjust.transaction do
        Teampointadjust.create!(school: school, points: 1)
        assert Rails.cache.exist?(summary_key)
      end
    end

    assert_not Rails.cache.exist?(summary_key)
  ensure
    Rails.cache.clear
  end
end
