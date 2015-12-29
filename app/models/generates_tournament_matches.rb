module GeneratesTournamentMatches

  def generateMatchups
    poolToBracket() if tournament_type == "Pool to bracket"
    matches
  end
  if Rails.env.production?
		handle_asynchronously :generateMatchups
	end

  def poolToBracket
    resetSchoolScores
    destroyAllMatches
    buildTournamentWeights
    generateMatches
  end

  def buildTournamentWeights
    weights.order(:max).each do |weight|
      Pool.new(weight).generatePools()
      last_match = matches.where(weight: weight).order(round: :desc).limit(1).first
      highest_round = last_match.round
      PoolBracket.new(weight, highest_round).generateBracketMatches()
    end
  end

  def generateMatches
    moveFinalsMatchesToLastRound
    assignBouts
    assignLoserNames
    assignFirstMatchesToMats
  end
  
  def moveFinalsMatchesToLastRound
    finalsRound = self.totalRounds
    finalsMatches = self.matches.select{|m| m.bracket_position == "1/2" || m.bracket_position == "3/4" || m.bracket_position == "5/6" || m.bracket_position == "7/8"}
    finalsMatches. each do |m|
      m.round = finalsRound
      m.save
    end
  end

end
