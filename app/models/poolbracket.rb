class Poolbracket

  def initialize(weight, highest_round)
    @weight = weight
    @tournament = @weight.tournament
    @pool_bracket_type = @weight.pool_bracket_type
    @round = highest_round + 1
  end

  def next_round
    @round += 1
  end

  def generateBracketMatches()
    if @pool_bracket_type == "twoPoolsToSemi"
      return twoPoolsToSemi()
    elsif @pool_bracket_type == "twoPoolsToFinal"
      return twoPoolsToFinal()
    elsif @pool_bracket_type == "fourPoolsToQuarter"
      return fourPoolsToQuarter()
    elsif @pool_bracket_type == "fourPoolsToSemi"
      return fourPoolsToSemi()
    end
    return []
  end

  def twoPoolsToSemi()
    createMatchup("Winner Pool 1", "Runner Up Pool 2", "Semis", 1)
    createMatchup("Winner Pool 2", "Runner Up Pool 1", "Semis", 2)
    next_round
    createMatchup("","","1/2",1)
    createMatchup("","","3/4",1)
  end

  def twoPoolsToFinal()
    createMatchup("Winner Pool 1", "Winner Pool 2", "1/2", 1)
    createMatchup("Runner Up Pool 1", "Runner Up Pool 2", "3/4", 1)
  end

  def fourPoolsToQuarter()
    createMatchup("Winner Pool 1", "Runner Up Pool 2", "Quarter", 1)
    createMatchup("Winner Pool 4", "Runner Up Pool 3", "Quarter", 2)
    createMatchup("Winner Pool 2", "Runner Up Pool 1", "Quarter", 3)
    createMatchup("Winner Pool 3", "Runner Up Pool 4", "Quarter", 4)
    next_round
    createMatchup("", "", "Semis", 1)
    createMatchup("", "", "Semis", 2)
    createMatchup("", "", "Conso Semis", 1)
    createMatchup("", "", "Conso Semis", 2)
    next_round
    createMatchup("", "", "1/2", 1)
    createMatchup("", "", "3/4", 1)
    createMatchup("", "", "5/6", 1)
    createMatchup("", "", "7/8", 1)
  end

  def fourPoolsToSemi()
    createMatchup("Winner Pool 1", "Winner Pool 4", "Semis", 1)
    createMatchup("Winner Pool 2", "Winner Pool 3", "Semis", 2)
    createMatchup("Runner Up Pool 1", "Runner Up Pool 4", "Conso Semis", 1)
    createMatchup("Runner Up Pool 2", "Runner Up Pool 3", "Conso Semis", 2)
    next_round
    createMatchup("", "", "1/2", 1)
    createMatchup("", "", "3/4", 1)
    createMatchup("", "", "5/6", 1)
    createMatchup("", "", "7/8", 1)
  end

  def createMatchup(w1_name, w2_name, bracket_position, bracket_position_number)
    @tournament.matches.create(
      loser1_name: w1_name,
      loser2_name: w2_name,
      weight_id: @weight.id,
      round: @round,
      bracket_position: bracket_position,
      bracket_position_number: bracket_position_number
    )
  end

end
