namespace :jobs do
  desc "Create a test running job for the first tournament"
  task create_running: :environment do
    # Find the first tournament
    tournament = Tournament.first
    
    unless tournament
      puts "No tournaments found. Please create a tournament first."
      exit 1
    end
    
    # Create a process record
    process = SolidQueue::Process.create!(
      kind: 'worker', 
      last_heartbeat_at: Time.now, 
      pid: Process.pid, 
      name: 'test_worker', 
      created_at: Time.now, 
      hostname: 'test'
    )
    
    # Create a job for the tournament
    job = SolidQueue::Job.create!(
      queue_name: 'default',
      class_name: 'TournamentBackupJob',
      arguments: JSON.generate([tournament.id, "Test job", tournament.id, "Test running job"]),
      priority: 0,
      active_job_id: SecureRandom.uuid,
      created_at: Time.now,
      updated_at: Time.now,
      job_owner_id: tournament.id,
      job_owner_type: "Test running job"
    )
    
    # Create a claimed execution to mark it as running
    SolidQueue::ClaimedExecution.create!(
      job_id: job.id,
      process_id: process.id,
      created_at: Time.now
    )
    
    puts "Created running job for tournament #{tournament.id} - #{tournament.name}"
    puts "Job ID: #{job.id}"
  end
  
  desc "Create a test completed job for the first tournament"
  task create_completed: :environment do
    # Find the first tournament
    tournament = Tournament.first
    
    unless tournament
      puts "No tournaments found. Please create a tournament first."
      exit 1
    end
    
    # Create a job for the tournament
    job = SolidQueue::Job.create!(
      queue_name: 'default',
      class_name: 'TournamentBackupJob',
      arguments: JSON.generate([tournament.id, "Test job", tournament.id, "Test completed job"]),
      priority: 0,
      active_job_id: SecureRandom.uuid,
      created_at: Time.now,
      updated_at: Time.now,
      finished_at: Time.now - 5.minutes,
      job_owner_id: tournament.id,
      job_owner_type: "Test completed job"
    )
    
    puts "Created completed job for tournament #{tournament.id} - #{tournament.name}"
    puts "Job ID: #{job.id}"
  end
  
  desc "Create a test failed job for the first tournament"
  task create_failed: :environment do
    # Find the first tournament
    tournament = Tournament.first
    
    unless tournament
      puts "No tournaments found. Please create a tournament first."
      exit 1
    end
    
    # Create a job for the tournament
    job = SolidQueue::Job.create!(
      queue_name: 'default',
      class_name: 'TournamentBackupJob',
      arguments: JSON.generate([tournament.id, "Test job", tournament.id, "Test failed job"]),
      priority: 0,
      active_job_id: SecureRandom.uuid,
      created_at: Time.now,
      updated_at: Time.now,
      finished_at: Time.now - 5.minutes,
      job_owner_id: tournament.id,
      job_owner_type: "Test failed job"
    )
    
    # Create a failed execution record
    SolidQueue::FailedExecution.create!(
      job_id: job.id,
      error: "Test error message",
      created_at: Time.now
    )
    
    puts "Created failed job for tournament #{tournament.id} - #{tournament.name}"
    puts "Job ID: #{job.id}"
  end
  
  desc "Test job owner metadata persistence"
  task test_metadata: :environment do
    # Find the first tournament
    tournament = Tournament.first
    
    unless tournament
      puts "No tournaments found. Please create a tournament first."
      exit 1
    end
    
    # Create a job with the new method
    puts "Creating a test job with job_owner_id: #{tournament.id} and job_owner_type: 'Test metadata job'"
    
    # Create a direct ActiveJob
    job = TournamentBackupJob.new(tournament, "Test metadata job")
    job.job_owner_id = tournament.id
    job.job_owner_type = "Test metadata job"
    
    # Enqueue it
    job_id = job.enqueue
    
    # Wait a moment for it to be saved
    sleep(1)
    
    # Find the job in SolidQueue
    sq_job = SolidQueue::Job.find_by(active_job_id: job.job_id)
    
    if sq_job
      puts "Job created and found in SolidQueue table:"
      puts "  ID: #{sq_job.id}"
      puts "  Active Job ID: #{sq_job.active_job_id}"
      
      # Extract metadata
      begin
        job_data = JSON.parse(sq_job.serialized_arguments)
        puts "  Raw serialized_arguments: #{sq_job.serialized_arguments}"
        
        if job_data.is_a?(Hash) && job_data["job_data"]
          puts "  Job data found:"
          puts "    job_owner_id: #{job_data["job_data"]["job_owner_id"]}"
          puts "    job_owner_type: #{job_data["job_data"]["job_owner_type"]}"
        else
          puts "  No job_data found in serialized arguments"
        end
      rescue JSON::ParserError
        puts "  Error parsing serialized arguments: #{sq_job.serialized_arguments}"
      end
      
      # Test the metadata method
      metadata = SolidQueueJobExtensions.instance_methods.include?(:metadata) ? 
                 sq_job.metadata : 
                 "metadata method not available"
      puts "  Metadata method result: #{metadata.inspect}"
      
      # Test the individual accessors
      if SolidQueueJobExtensions.instance_methods.include?(:job_owner_id) && 
         SolidQueueJobExtensions.instance_methods.include?(:job_owner_type)
        puts "  job_owner_id method: #{sq_job.job_owner_id}"
        puts "  job_owner_type method: #{sq_job.job_owner_type}"
      else
        puts "  Job owner accessor methods not available"
      end
    else
      puts "Job not found in SolidQueue table. Check for errors."
    end
  end
  
  desc "Check existing job metadata"
  task check_jobs: :environment do
    puts "Checking existing jobs in SolidQueue table"
    
    # Find recent jobs
    jobs = SolidQueue::Job.order(created_at: :desc).limit(5)
    
    if jobs.empty?
      puts "No jobs found in SolidQueue table."
      exit 0
    end
    
    puts "Found #{jobs.count} jobs:"
    
    jobs.each_with_index do |job, index|
      puts "\nJob ##{index + 1}:"
      puts "  ID: #{job.id}"
      puts "  Class: #{job.class_name}"
      puts "  Created at: #{job.created_at}"
      
      # Display the raw serialized arguments
      puts "  Raw arguments:"
      puts "    #{job.arguments.to_s[0..200]}..."
      
      # Parse the serialized arguments to extract relevant parts
      begin
        args_data = job.arguments.is_a?(Hash) ? job.arguments : JSON.parse(job.arguments)
        if args_data.is_a?(Hash) && args_data["arguments"].is_a?(Array)
          puts "  Arguments array:"
          args_data["arguments"].each_with_index do |arg, i|
            puts "    [#{i}]: #{arg.inspect}"
          end
        end
      rescue JSON::ParserError
        puts "  Error: Could not parse arguments"
      rescue => e
        puts "  Error: #{e.message}"
      end
      
      # Test the metadata extraction method
      metadata = job.respond_to?(:metadata) ? job.metadata : nil
      puts "  Extracted metadata: #{metadata.inspect}"
      
      if job.respond_to?(:job_owner_id) && job.respond_to?(:job_owner_type)
        puts "  job_owner_id: #{job.job_owner_id}"
        puts "  job_owner_type: #{job.job_owner_type}"
      end
    end
  end
  
  desc "Test create a tournament backup job with metadata"
  task create_test_backup_job: :environment do
    puts "Creating a test TournamentBackupJob with job owner metadata"
    
    # Find a tournament to use
    tournament = Tournament.first
    
    if tournament.nil?
      puts "No tournament found in the database. Creating a test tournament."
      tournament = Tournament.create!(name: "Test Tournament", tournament_type: 0)
    end
    
    puts "Using tournament ##{tournament.id}: #{tournament.name}"
    
    # Set test job owner metadata
    job_owner_id = 999
    job_owner_type = "Test Backup Creation"
    
    # Create the job with owner metadata
    job = TournamentBackupJob.perform_later(tournament, "Test backup", job_owner_id, job_owner_type)
    puts "Created job with ID: #{job.job_id}"
    
    # Retrieve the job from the database to verify metadata
    puts "\nChecking job in the database:"
    sleep(1) # Give a moment for the job to be persisted
    
    solid_job = SolidQueue::Job.order(created_at: :desc).first
    
    if solid_job
      puts "Found job ##{solid_job.id} (#{solid_job.class_name})"
      
      begin
        # Parse the arguments
        arg_data = solid_job.arguments
        if arg_data.is_a?(String)
          begin
            arg_data = JSON.parse(arg_data)
          rescue JSON::ParserError => e
            puts "Failed to parse arguments as JSON: #{e.message}"
          end
        end
        
        if arg_data.is_a?(Hash) && arg_data["arguments"].is_a?(Array)
          puts "Arguments:"
          arg_data["arguments"].each_with_index do |arg, i|
            puts "  [#{i}]: #{arg.inspect.truncate(100)}"
          end
          
          # Check if we can extract metadata
          metadata = solid_job.metadata rescue nil
          if metadata
            puts "Extracted metadata: #{metadata.inspect}"
            puts "job_owner_id: #{metadata['job_owner_id']}"
            puts "job_owner_type: #{metadata['job_owner_type']}"
          else
            puts "No metadata method available"
          end
        else
          puts "No arguments array found in job data"
        end
      rescue => e
        puts "Error inspecting job: #{e.message}"
      end
    else
      puts "No job found in the database"
    end
  end
  
  desc "Debug tournament job detection for a specific tournament"
  task debug_tournament_jobs: :environment do
    tournament_id = ENV['TOURNAMENT_ID']
    
    if tournament_id.blank?
      puts "Usage: rake jobs:debug_tournament_jobs TOURNAMENT_ID=123"
      exit 1
    end
    
    tournament = Tournament.find_by(id: tournament_id)
    
    if tournament.nil?
      puts "Tournament not found with id: #{tournament_id}"
      exit 1
    end
    
    puts "== Debugging job detection for Tournament ##{tournament.id}: #{tournament.name} =="
    
    # Get all jobs
    all_jobs = SolidQueue::Job.all
    puts "Total jobs in system: #{all_jobs.count}"
    
    # Test each condition independently to see which jobs match
    condition1_jobs = all_jobs.select do |job|
      if job.respond_to?(:job_owner_id) && job.job_owner_id.present?
        job.job_owner_id.to_s == tournament.id.to_s
      else
        false
      end
    end
    
    condition2_jobs = all_jobs.select do |job|
      if job.respond_to?(:metadata)
        metadata = job.metadata
        metadata["job_owner_id"].present? && metadata["job_owner_id"].to_s == tournament.id.to_s
      else
        false
      end
    end
    
    condition3_jobs = all_jobs.select do |job|
      if job.arguments.present?
        begin
          args_data = job.arguments.is_a?(Hash) ? job.arguments : JSON.parse(job.arguments.to_s)
          if args_data.is_a?(Hash) && args_data["arguments"].is_a?(Array) && args_data["arguments"][0].present?
            args_data["arguments"][0].to_s == tournament.id.to_s
          else
            false
          end
        rescue
          false
        end
      else
        false
      end
    end
    
    puts "Jobs matching condition 1 (direct job_owner_id): #{condition1_jobs.count}"
    puts "Jobs matching condition 2 (metadata method): #{condition2_jobs.count}"
    puts "Jobs matching condition 3 (first argument): #{condition3_jobs.count}"
    
    # Test the actual method
    tournament_jobs = tournament.deferred_jobs
    puts "Jobs returned by tournament.deferred_jobs: #{tournament_jobs.count}"
    
    # Show details about each job
    if tournament_jobs.any?
      puts "\nDetails of jobs found by tournament.deferred_jobs:"
      tournament_jobs.each_with_index do |job, index|
        puts "\nJob ##{index + 1} (ID: #{job.id}):"
        puts "  Class: #{job.class_name}"
        
        # Try to get metadata
        if job.respond_to?(:metadata)
          metadata = job.metadata
          puts "  Metadata: #{metadata.inspect}"
        end
        
        # Display raw arguments
        begin
          if job.arguments.is_a?(String) && job.arguments.present?
            parsed = JSON.parse(job.arguments)
            args = parsed["arguments"] if parsed.is_a?(Hash)
            puts "  Arguments: #{args.inspect}" if args
          elsif job.arguments.is_a?(Hash) && job.arguments["arguments"].present?
            puts "  Arguments: #{job.arguments["arguments"].inspect}"
          end
        rescue => e
          puts "  Error parsing arguments: #{e.message}"
        end
      end
    end
  end
  
  desc "Scan all jobs to detect job owner IDs"
  task scan_jobs: :environment do
    puts "Scanning all SolidQueue jobs to detect job owner information"
    
    all_jobs = SolidQueue::Job.all.order(created_at: :desc)
    puts "Found #{all_jobs.count} total jobs"
    
    # Group by job type
    job_types = all_jobs.group_by(&:class_name)
    puts "\nJobs by type:"
    job_types.each do |type, jobs|
      puts "  #{type}: #{jobs.count} jobs"
    end
    
    # Go through each job and extract job owner info
    owner_info = {}
    
    all_jobs.each do |job|
      owner_id = nil
      owner_type = nil
      tournament_id = nil
      
      # Method 1: Check direct job_owner_id attribute
      if job.respond_to?(:job_owner_id) && job.job_owner_id.present?
        owner_id = job.job_owner_id
      end
      
      # Method 2: Check metadata method
      if job.respond_to?(:metadata)
        metadata = job.metadata
        if metadata.is_a?(Hash) && metadata["job_owner_id"].present?
          owner_id ||= metadata["job_owner_id"]
          owner_type = metadata["job_owner_type"]
        end
      end
      
      # Method 3: Extract tournament ID from the arguments
      if job.arguments.present?
        arg_data = job.arguments
        
        # Handle hash arguments
        if arg_data.is_a?(Hash) && arg_data["arguments"].is_a?(Array) && arg_data["arguments"].first.present?
          first_arg = arg_data["arguments"].first
          
          # Check if the first argument is a Tournament global ID
          if first_arg.is_a?(Hash) && first_arg["_aj_globalid"].present?
            global_id = first_arg["_aj_globalid"]
            if global_id.to_s.include?("/Tournament/")
              tournament_id = global_id.to_s.split("/Tournament/").last
            end
          else
            # Direct ID - assume it's a tournament ID
            tournament_id = first_arg.to_s
          end
        end
        
        # If it's a string, try to parse
        if arg_data.is_a?(String)
          begin
            parsed = JSON.parse(arg_data)
            if parsed.is_a?(Hash) && parsed["arguments"].is_a?(Array) && parsed["arguments"].first.present?
              first_arg = parsed["arguments"].first
              
              # Check if the first argument is a Tournament global ID
              if first_arg.is_a?(Hash) && first_arg["_aj_globalid"].present?
                global_id = first_arg["_aj_globalid"]
                if global_id.to_s.include?("/Tournament/")
                  tournament_id = global_id.to_s.split("/Tournament/").last
                end
              else
                # Direct ID - assume it's a tournament ID
                tournament_id = first_arg.to_s
              end
            end
          rescue
            # Ignore parsing errors
          end
        end
      end
      
      # Record what we found
      owner_info[job.id] = {
        job_id: job.id,
        class_name: job.class_name,
        owner_id: owner_id,
        owner_type: owner_type,
        tournament_id: tournament_id,
        created_at: job.created_at
      }
    end
    
    # Group by tournament ID
    tournament_groups = owner_info.values.group_by { |info| info[:tournament_id] }
    
    puts "\nJobs by tournament ID:"
    tournament_groups.each do |tournament_id, jobs|
      next if tournament_id.nil?
      tournament = Tournament.find_by(id: tournament_id) rescue nil
      tournament_name = tournament ? tournament.name : "Unknown"
      puts "  Tournament ##{tournament_id} (#{tournament_name}): #{jobs.count} jobs"
      
      # Sample job details
      sample = jobs.first
      puts "    Sample job: #{sample[:class_name]} (ID: #{sample[:job_id]})"
      puts "    Created at: #{sample[:created_at]}"
      puts "    Owner ID: #{sample[:owner_id]}"
      puts "    Owner Type: #{sample[:owner_type]}"
    end
    
    # Orphaned jobs
    orphaned = owner_info.values.select { |info| info[:tournament_id].nil? }
    if orphaned.any?
      puts "\nOrphaned jobs (no tournament ID detected): #{orphaned.count} jobs"
      orphaned.first(5).each do |job|
        puts "  #{job[:class_name]} (ID: #{job[:job_id]}) created at #{job[:created_at]}"
      end
    end
  end
end 