module GeneratesTournamentMatches

  def generateMatchups
    self.curently_generating_matches = 1
    self.save
    resetSchoolScores
    setSeedsAndRandomSeedingWrestlersWithoutSeeds
    poolToBracket() if tournament_type == "Pool to bracket"
    self.curently_generating_matches = nil
    self.save
  end
  if Rails.env.production?
		handle_asynchronously :generateMatchups
  end

  def poolToBracket
    destroyAllMatches
    generatePoolToBracketMatches
    poolToBracketPostMatchCreation
  end

  def generatePoolToBracketMatches
    weights.order(:max).each do |weight|
      Pool.new(weight).generatePools()
      last_match = matches.where(weight: weight).order(round: :desc).limit(1).first
      highest_round = last_match.round
      PoolBracket.new(weight, highest_round).generateBracketMatches()
    end
  end

  def poolToBracketPostMatchCreation
    moveFinalsMatchesToLastRound
    assignBouts
    assignLoserNames
    assignFirstMatchesToMats
    movePoolSeedsToFinalPoolRound
  end
  
  def moveFinalsMatchesToLastRound
    finalsRound = self.totalRounds
    finalsMatches = self.matches.select{|m| m.bracket_position == "1/2" || m.bracket_position == "3/4" || m.bracket_position == "5/6" || m.bracket_position == "7/8"}
    finalsMatches. each do |m|
      m.round = finalsRound
      m.save
    end
  end
  
  def setSeedsAndRandomSeedingWrestlersWithoutSeeds
    weights.each do |w|
      w.setSeeds
    end
  end
  
  def movePoolSeedsToFinalPoolRound
    self.weights.each do |w|
      w.setOriginalSeedsToWrestleLastPoolRound
    end
  end

end
