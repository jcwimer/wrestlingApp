class GenerateTournamentMatches
    def initialize( tournament )
      @tournament = tournament
    end

    def generate
      if Rails.env.production?
        self.delay(:job_owner_id => @tournament.id, :job_owner_type => "Generate matches for all weights").generate_raw
      else
        self.generate_raw
      end        
    end

    def generate_raw
        standardStartingActions
        PoolToBracketMatchGeneration.new(@tournament).generatePoolToBracketMatches if @tournament.tournament_type == "Pool to bracket"
        ModifiedSixteenManMatchGeneration.new(@tournament).generate_matches if @tournament.tournament_type.include? "Modified 16 Man Double Elimination"
        DoubleEliminationMatchGeneration.new(@tournament).generate_matches if @tournament.tournament_type.include? "Regular Double Elimination"
        postMatchCreationActions
        PoolToBracketMatchGeneration.new(@tournament).assignLoserNames if @tournament.tournament_type == "Pool to bracket"
        ModifiedSixteenManGenerateLoserNames.new(@tournament).assign_loser_names if @tournament.tournament_type.include? "Modified 16 Man Double Elimination"
        DoubleEliminationGenerateLoserNames.new(@tournament).assign_loser_names if @tournament.tournament_type.include? "Regular Double Elimination"
    end

    def standardStartingActions
        @tournament.curently_generating_matches = 1
        @tournament.save
        WipeTournamentMatches.new(@tournament).setUpMatchGeneration
        TournamentSeeding.new(@tournament).set_seeds
    end

    def postMatchCreationActions
        moveFinalsMatchesToLastRound
        assignBouts
        @tournament.reset_and_fill_bout_board
        @tournament.curently_generating_matches = nil
        @tournament.save!
    end

    def assignBouts
      bout_counts = Hash.new(0)
      @tournament.matches.reload
      @tournament.matches.sort_by{|m| [m.round, m.weight_max]}.each do |m|
        m.bout_number = m.round * 1000 + bout_counts[m.round]
        bout_counts[m.round] += 1
        m.save!
      end
    end

    def moveFinalsMatchesToLastRound
      finalsRound = @tournament.reload.total_rounds
      finalsMatches = @tournament.matches.reload.select{|m| m.bracket_position == "1/2" || m.bracket_position == "3/4" || m.bracket_position == "5/6" || m.bracket_position == "7/8"}
      finalsMatches. each do |m|
        m.round = finalsRound
        m.save
      end
    end

    def unAssignMats
      matches = @tournament.matches.reload
      matches.each do |m|
        m.mat_id = nil
        m.save!
      end
    end

    def unAssignBouts
      bout_counts = Hash.new(0)
      @tournament.matches.each do |m|
        m.bout_number = nil
        m.save!
      end
    end
end
