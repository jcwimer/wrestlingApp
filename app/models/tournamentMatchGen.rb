class Tournamentmatchgen
  def genMatches(tournament)
    if tournament.tournament_type == "Pool to bracket"
      @matches = poolToBracket(tournament)
    end
    return @matches
  end

  def poolToBracket(tournament)
    tournament.destroyAllMatches
    @matches = []
    tournament.weights.sort_by{|x|[x.max]}.each do |w|
      @wrestlers = w.wrestlers
      @matches = Pool.new.generatePools(w.pools,@wrestlers,w,tournament.id,@matches)
      @weight_matches = @matches.select{|m|m.weight_id == w.id}
      @last_match = @weight_matches.sort_by{|m| m.round}.last
      @highest_round = @last_match.round
      @matches = Poolbracket.new.generateBracketMatches(@matches,w,@highest_round)
    end
    @matches = Boutgen.new.assignBouts(@matches,tournament.weights)
    @matches = Losernamegen.new.assignLoserNames(@matches,tournament.weights)
    saveMatches(tournament,@matches)
    return @matches
  end

  def saveMatches(tournament,matches)
    matches.each do |m|
      m.tournament_id = tournament.id
      m.save
    end
  end
end

