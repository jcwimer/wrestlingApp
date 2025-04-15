require "test_helper"

class TournamentJobStatusTest < ActiveSupport::TestCase
  setup do
    @tournament = tournaments(:one)
    
    # Create a second tournament
    @tournament_two = Tournament.create!(
      name: "Second Tournament",
      address: "Some Address",
      director: "Test Director",
      director_email: "test@example.com",
      tournament_type: "Pool to bracket",
      date: Date.today,
      is_public: true
    )
    
    # Create fresh test data for each test
    @queued_job = TournamentJobStatus.create!(
      tournament: @tournament,
      job_name: "Test Queued Job",
      status: "Queued",
      details: "Test job details"
    )
    
    @running_job = TournamentJobStatus.create!(
      tournament: @tournament,
      job_name: "Test Running Job",
      status: "Running",
      details: "Test running job details"
    )
    
    @errored_job = TournamentJobStatus.create!(
      tournament: @tournament,
      job_name: "Test Errored Job",
      status: "Errored",
      details: "Test error message"
    )
    
    # Create job for another tournament
    @another_tournament_job = TournamentJobStatus.create!(
      tournament: @tournament_two,
      job_name: "Another Tournament Job",
      status: "Running",
      details: "Different tournament test"
    )
  end
  
  teardown do
    # Clean up test data
    TournamentJobStatus.destroy_all
    @tournament_two.destroy if @tournament_two.present?
  end
  
  test "should be valid with required fields" do
    job_status = TournamentJobStatus.new(
      tournament: @tournament,
      job_name: "Test Job",
      status: "Queued"
    )
    assert job_status.valid?
  end
  
  test "should require tournament" do
    job_status = TournamentJobStatus.new(
      job_name: "Test Job",
      status: "Queued"
    )
    assert_not job_status.valid?
  end
  
  test "should require job_name" do
    job_status = TournamentJobStatus.new(
      tournament: @tournament,
      status: "Queued"
    )
    assert_not job_status.valid?
  end
  
  test "should require status" do
    job_status = TournamentJobStatus.new(
      tournament: @tournament,
      job_name: "Test Job"
    )
    job_status.status = nil
    job_status.valid?
    assert_includes job_status.errors[:status], "can't be blank"
  end
  
  test "status should be one of the allowed values" do
    job_status = TournamentJobStatus.new(
      tournament: @tournament,
      job_name: "Test Job",
      status: "Invalid Status"
    )
    assert_not job_status.valid?
    
    ["Queued", "Running", "Errored"].each do |valid_status|
      job_status.status = valid_status
      assert job_status.valid?, "Status #{valid_status} should be valid"
    end
  end
  
  test "active scope should exclude errored jobs" do
    active_jobs = TournamentJobStatus.active
    assert_includes active_jobs, @queued_job
    assert_includes active_jobs, @running_job
    assert_not_includes active_jobs, @errored_job
  end
  
  test "for_tournament should return only jobs for a specific tournament" do
    tournament_one_jobs = TournamentJobStatus.for_tournament(@tournament)
    
    assert_equal 3, tournament_one_jobs.count
    assert_includes tournament_one_jobs, @queued_job
    assert_includes tournament_one_jobs, @running_job
    assert_includes tournament_one_jobs, @errored_job
    assert_not_includes tournament_one_jobs, @another_tournament_job
  end
  
  test "complete_job should remove jobs with matching tournament_id and job_name" do
    job_count_before = TournamentJobStatus.count
    
    assert_difference 'TournamentJobStatus.count', -1 do
      TournamentJobStatus.complete_job(@tournament.id, "Test Running Job")
    end
    
    assert_nil TournamentJobStatus.find_by(id: @running_job.id)
  end
end
