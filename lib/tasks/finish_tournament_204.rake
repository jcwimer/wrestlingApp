namespace :tournament do
    desc "Assign random win types and scores to matches"
    task assign_random_wins: :environment do
      WIN_TYPES = ["Decision", "Major", "Tech Fall", "Pin"]
  
      @tournament = Tournament.find(204)

      Mat.find_or_create_by(
        name: "1",
        tournament_id: @tournament.id
      )
      Mat.find_or_create_by(
        name: "2",
        tournament_id: @tournament.id
      )
      Mat.find_or_create_by(
        name: "3",
        tournament_id: @tournament.id
      )
      Mat.find_or_create_by(
        name: "4",
        tournament_id: @tournament.id
      )
      Mat.find_or_create_by(
        name: "5",
        tournament_id: @tournament.id
      )

      GenerateTournamentMatches.new(@tournament).generate
      sleep(60)
      while @tournament.reload.curently_generating_matches == 1
        puts "Waiting for tournament to finish generating matches..."
        sleep(5)
        @tournament.reload
      end
  
      sleep(10)
      loop do
        @tournament.reload
        @tournament.refill_open_bout_board_queues

        mats_with_queue1 = @tournament.mats.select do |mat|
          match = mat.queue1_match
          match && match.finished != 1 && match.loser1_name != "BYE" && match.loser2_name != "BYE"
        end

        break if mats_with_queue1.empty?

        mat = mats_with_queue1.sample
        match = mat.queue1_match

        # Wait until both wrestlers are assigned for the selected queue1 match.
        while match && (match.w1.nil? || match.w2.nil?)
          puts "Waiting for wrestlers in match #{match.bout_number} on mat #{mat.name}..."
          sleep(5)
          @tournament.reload
          @tournament.refill_open_bout_board_queues
          match = mat.reload.queue1_match
        end

        next unless match
        next if match.finished == 1 || match.loser1_name == "BYE" || match.loser2_name == "BYE"

        puts "Finishing queue1 match on mat #{mat.name} with bout number #{match.bout_number}..."

        # Choose a random winner
        wrestlers = [match.w1, match.w2]
        match.winner_id = wrestlers.sample

        # Choose a random win type
        win_type = WIN_TYPES.sample
        match.win_type = win_type

        # Assign score based on win type
        match.score = case win_type
                      when "Decision"
                        low_score = rand(0..10)
                        high_score = low_score + rand(1..7)
                        "#{high_score}-#{low_score}"
                      when "Major"
                        low_score = rand(0..10)
                        high_score = low_score + rand(8..14)
                        "#{high_score}-#{low_score}"
                      when "Tech Fall"
                        low_score = rand(0..10)
                        high_score = low_score + rand(15..19)
                        "#{high_score}-#{low_score}"
                      when "Pin"
                        pin_times = ["0:30","1:12","5:37","2:34","3:54","4:23","5:56","0:12","1:00"]
                        pin_times.sample
                      else
                        ""
                      end

        # Mark match as finished
        match.finished = 1
        match.save!
        # sleep to prevent mysql locks when queue advancement runs
        sleep(0.5)
      end
    end
  end
  
