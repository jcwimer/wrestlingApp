class Tournamentmatchgen

  def initialize(tournament)
    @tournament = tournament
    @matches = @tournament.matches
  end

  def genMatches
    if @tournament.tournament_type == "Pool to bracket"
      @matches = poolToBracket()
    end
    @matches
  end

  def poolToBracket
    destroyMatches
    buildTournamentWeights
    generateMatches
    saveMatches
    @matches
  end

  def destroyMatches
    @tournament.destroyAllMatches
    @matches = []
  end

  def buildTournamentWeights
    @tournament.weights.sort_by{|x|[x.max]}.each do |weight|
      matches = Pool.new(weight).generatePools()
      last_match = matches.sort_by{|m| m.round}.last
      highest_round = last_match.round
      @matches += Poolbracket.new.generateBracketMatches(matches, weight, highest_round)
    end
  end

  def generateMatches
    @matches =
      Losernamegen.new.assignLoserNames(
        Boutgen.new.assignBouts(@matches, @tournament.weights),
        @tournament.weights)
  end

  def saveMatches
    @tournament.save!
    @matches.each do |m|
      m.save
    end
  end

end
