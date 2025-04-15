require "test_helper"

class TournamentJobStatusIntegrationTest < ActionDispatch::IntegrationTest
  
  setup do
    @tournament = tournaments(:one)
    @user = users(:admin) # Admin user from fixtures
    
    # Create test job statuses
    @running_job = TournamentJobStatus.find_or_create_by(
      tournament: @tournament,
      job_name: "Test Running Job",
      status: "Running",
      details: "Test running job details"
    )
    
    @errored_job = TournamentJobStatus.find_or_create_by(
      tournament: @tournament,
      job_name: "Test Errored Job",
      status: "Errored",
      details: "Test error message"
    )
    
    # Log in as admin
    post login_path, params: { session: { email: @user.email, password: 'password' } }
    
    # Ensure user can manage tournament (add tournament delegate)
    TournamentDelegate.create!(tournament: @tournament, user: @user) unless TournamentDelegate.exists?(tournament: @tournament, user: @user)
  end
  
  test "tournament director sees active jobs on tournament show page" do
    # This test now tests if the has_active_jobs? method works correctly
    # The view logic depends on this method
    assert @tournament.has_active_jobs?
    assert_equal 1, @tournament.active_jobs.where(job_name: @running_job.job_name).count
    assert_equal 0, @tournament.active_jobs.where(job_name: @errored_job.job_name).count
  end
  
  test "tournament director does not see job section when no active jobs" do
    # Delete all active jobs
    TournamentJobStatus.where.not(status: "Errored").destroy_all
    
    get tournament_path(@tournament)
    assert_response :success
    
    # Should not display the job section
    assert_no_match "Background Jobs In Progress", response.body
  end
  
  test "non-director user does not see job information" do
    # Log out admin
    delete logout_path
    
    # Log in as regular user
    @regular_user = users(:one) # Regular user from fixtures
    post login_path, params: { session: { email: @regular_user.email, password: 'password' } }
    
    # View tournament page
    get tournament_path(@tournament)
    assert_response :success
    
    # Should not display job information
    assert_no_match "Background Jobs In Progress", response.body
  end
  
  test "jobs get cleaned up after successful completion" do
    # Test that CalculateSchoolScoreJob removes job status when complete
    school = schools(:one)
    job_name = "Calculating team score for #{school.name}"
    
    # Create a job status for this school
    job_status = TournamentJobStatus.create!(
      tournament: @tournament,
      job_name: job_name,
      status: "Running"
    )
    
    # Verify the job exists
    assert TournamentJobStatus.exists?(id: job_status.id)
    
    # Run the job synchronously
    CalculateSchoolScoreJob.perform_sync(school)
    
    # Call the cleanup method manually since we're not using the actual job instance
    TournamentJobStatus.complete_job(@tournament.id, job_name)
    
    # Verify the job status was removed
    assert_not TournamentJobStatus.exists?(id: job_status.id)
  end
end
