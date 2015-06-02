module GeneratesLoserNames
  def assignLoserNames
    weights.each do |w|
      if w.pool_bracket_type == "twoPoolsToSemi"
        twoPoolsToSemiLoser(w)
      elsif w.pool_bracket_type == "fourPoolsToQuarter"
        fourPoolsToQuarterLoser(w)
      elsif w.pool_bracket_type == "fourPoolsToSemi"
        fourPoolsToSemiLoser(w)
      end
    end
  end

  def twoPoolsToSemiLoser(weight)
    matchChange = thirdFourth(weight)
    matchChange.loser1_name = "Loser of #{winner_pool_1_match(weight).bout_number}"
    matchChange.loser2_name = "Loser of #{winner_pool_2_match(weight).bout_number}"
    matchChange.save!
  end

  def updateLosers(updated, group, position1, position2)
    match1 = bracket_position_bout_number(group, position1)
    match2 = bracket_position_bout_number(group, position2)
    updated.loser1_name = "Loser of #{match1}"
    updated.loser2_name = "Loser of #{match2}"
    updated.save!
  end

  def bracket_position_bout_number(group, bracket_position)
    bracket_match = group.detect do |m|
      m.bracket_position_number == bracket_position
    end
    bracket_match.bout_number
  end

  def matches_by_weight(weight)
    matches.where(weight_id: weight.id)
  end

  def winner_pool_1_match(weight)
    matches_by_weight(weight).where(loser1_name: "Winner Pool 1").limit(1).first
  end

  def winner_pool_2_match(weight)
    matches_by_weight(weight).where(loser1_name: "Winner Pool 2").limit(1).first
  end

  def quarters(weight)
    matches_by_weight(weight).where(bracket_position: "Quarter")
  end

  def consoSemis(weight)
    matches_by_weight(weight).where(bracket_position: "Conso Semis")
  end

  def semis(weight)
    matches_by_weight(weight).where(bracket_position: "Semis")
  end

  def thirdFourth(weight)
    matches_by_weight(weight).where(bracket_position: "3/4").limit(1).first
  end

  def seventhEighth(weight)
    matches_by_weight(weight).where(bracket_position: "7/8").limit(1).first
  end

  def fourPoolsToQuarterLoser(weight)
    consoSemis(weight).each do |m|
      if m.bracket_position_number == 1
        updateLosers(m, quarters(weight), 1, 2)
      elsif m.bracket_position_number == 2
        updateLosers(m, quarters(weight), 3, 4)
      end
    end
    fourPoolsToSemiLoser(weight)
  end

  def fourPoolsToSemiLoser(weight)
    updateLosers(thirdFourth(weight), semis(weight), 1, 2)
    updateLosers(seventhEighth(weight), consoSemis(weight), 1, 2)
  end

end
