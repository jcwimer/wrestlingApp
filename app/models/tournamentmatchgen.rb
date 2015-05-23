class Tournamentmatchgen

  def initialize(tournament)
    @tournament = tournament
    @matches = @tournament.matches
  end

  def genMatches
    if @tournament.tournament_type == "Pool to bracket"
      @matches = poolToBracket()
    end
    return @matches
  end

  def poolToBracket
    destroyMatches()
    @tournament.weights.sort_by{|x|[x.max]}.each do |w|
      buildTournamentWeights(w)
    end
    @matches = Boutgen.new.assignBouts(@matches,@tournament.weights)
    @matches = Losernamegen.new.assignLoserNames(@matches,@tournament.weights)
    saveMatches
    return @matches
  end

  def destroyMatches
    @tournament.destroyAllMatches
    @matches = []
  end

  def buildTournamentWeights(weight)
    @wrestlers = weight.wrestlers
    @matches = Pool.new.generatePools(weight, @tournament.id, @matches)
    @weight_matches = @matches.select{|m| m.weight_id == weight.id }
    @last_match = @weight_matches.sort_by{|m| m.round}.last
    @highest_round = @last_match.round
    @matches = Poolbracket.new.generateBracketMatches(@matches, weight, @highest_round)
  end

  def saveMatches
    @matches.each do |m|
      m.tournament_id = @tournament.id
      m.save
    end
  end
end
