namespace :tournament do
    desc "Assign random win types and scores to matches"
    task assign_random_wins: :environment do
      WIN_TYPES = ["Decision", "Major", "Tech Fall", "Pin"]
  
      @tournament = Tournament.find(204)

      Mat.create(
        name: "1",
        tournament_id: @tournament.id
      )
      Mat.create(
        name: "2",
        tournament_id: @tournament.id
      )
      Mat.create(
        name: "3",
        tournament_id: @tournament.id
      )
      Mat.create(
        name: "4",
        tournament_id: @tournament.id
      )
      Mat.create(
        name: "5",
        tournament_id: @tournament.id
      )

      GenerateTournamentMatches.new(@tournament).generate
      sleep(180)
  
      @tournament.matches.sort_by(&:bout_number).each do |match|
        match.reload
        if match.loser1_name != "BYE" and match.loser2_name != "BYE"
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
                            "" # Default score
                        end
    
            # Mark match as finished
            match.finished = 1
            match.save
    
            # Pause to simulate processing delay
            sleep(10)
        end
      end
    end
  end
  