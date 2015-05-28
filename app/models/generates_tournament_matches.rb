module GeneratesTournamentMatches

  def generateMatchups
    poolToBracket() if tournament_type == "Pool to bracket"
    matches
  end

  def poolToBracket
    destroyAllMatches
    buildTournamentWeights
    generateMatches
  end

  def buildTournamentWeights
    weights.order(:max).each do |weight|
      Pool.new(weight).generatePools()
      last_match = matches.where(weight: weight).order(round: :desc).limit(1).first
      highest_round = last_match.round
      Poolbracket.new(weight, highest_round).generateBracketMatches()
    end
  end

  def generateMatches
    assignBouts
    assignLoserNames
  end

end
