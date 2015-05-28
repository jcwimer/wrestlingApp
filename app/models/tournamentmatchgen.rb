class Tournamentmatchgen

  def initialize(tournament)
    @tournament = tournament
  end

  def genMatches
    if @tournament.tournament_type == "Pool to bracket"
      poolToBracket()
    end
    @tournament.matches
  end

  def poolToBracket
    destroyMatches
    buildTournamentWeights
    generateMatches
  end

  def destroyMatches
    @tournament.destroyAllMatches
  end

  def buildTournamentWeights
    @tournament.weights.order(:max).each do |weight|
      Pool.new(weight).generatePools()
      last_match = @tournament.matches.where(weight: weight).order(round: :desc).limit(1).first
      highest_round = last_match.round
      Poolbracket.new(weight, highest_round).generateBracketMatches()
    end
  end

  def generateMatches
    @tournament.assignBouts
    @tournament.assignLoserNames
  end
end
