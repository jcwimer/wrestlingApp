require 'test_helper'

class TournamentCleanupJobTest < ActiveJob::TestCase
  setup do
    # Create an old empty tournament (1 week old, 0 finished matches)
    @old_empty_tournament = tournaments(:one)
    @old_empty_tournament.update(date: 2.weeks.ago.to_date)
    
    # Create an old active tournament (1 week old, with finished matches)
    @old_active_tournament = tournaments(:two)
    @old_active_tournament.update(date: 2.weeks.ago.to_date)
    
    # Add a finished match to the active tournament using create instead of fixtures
    weight = Weight.create(max: 120, tournament: @old_active_tournament)
    wrestler = Wrestler.create(name: "Test Wrestler", weight: weight, school: schools(:one))
    
    @match = Match.create(
      tournament: @old_active_tournament,
      weight: weight,
      bracket_position: "Pool",
      round: 1,
      finished: 1,
      win_type: "Decision",
      score: "10-5",
      w1: wrestler.id,
      winner_id: wrestler.id
    )
    
    # Add delegates to test removal
    tournament_delegate = TournamentDelegate.create(tournament: @old_active_tournament, user: users(:one))
    school = schools(:one)
    school.update(tournament_id: @old_active_tournament.id)
    school_delegate = SchoolDelegate.create(school: school, user: users(:one))
  end

  test "removes old empty tournaments" do
    # In this test, only the empty tournament should be deleted
    @match.update!(win_type: "Decision") # Ensure this tournament has a non-BYE match
    
    assert_difference 'Tournament.count', -1 do
      TournamentCleanupJob.perform_now
    end
    
    assert_raises(ActiveRecord::RecordNotFound) { @old_empty_tournament.reload }
    assert_nothing_raised { @old_active_tournament.reload }
  end

  test "removes old empty tournaments with only a bye finished match" do
    # Update the win_type to BYE and score to empty as required by validation
    @match.update!(win_type: "BYE", score: "")
    assert_equal "BYE", @match.reload.win_type
    assert_equal "", @match.score
    
    # Both tournaments should be deleted (the empty one and the one with only BYE matches)
    assert_difference 'Tournament.count', -2 do
      TournamentCleanupJob.perform_now
    end
    
    assert_raises(ActiveRecord::RecordNotFound) { @old_empty_tournament.reload }
    assert_raises(ActiveRecord::RecordNotFound) { @old_active_tournament.reload }
  end

  test "cleans up old active tournaments" do
    # Ensure this tournament has a non-BYE match
    @match.update!(win_type: "Decision") 
    
    TournamentCleanupJob.perform_now
    
    # Tournament should still exist
    @old_active_tournament.reload
    
    # User association should be removed
    assert_nil @old_active_tournament.user_id
    
    # Tournament delegates should be removed
    assert_equal 0, @old_active_tournament.delegates.count
    
    # School delegates should be removed
    @old_active_tournament.schools.each do |school|
      assert_equal 0, school.delegates.count
    end
  end
end 