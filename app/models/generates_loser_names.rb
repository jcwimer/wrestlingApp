module GeneratesLoserNames
  def assignLoserNames
    weights.each do |w|
      if w.pool_bracket_type == "twoPoolsToSemi"
        twoPoolsToSemiLoser(matches_by_weight(w))
      elsif w.pool_bracket_type == "fourPoolsToQuarter"
        fourPoolsToQuarterLoser(matches_by_weight(w))
      elsif w.pool_bracket_type == "fourPoolsToSemi"
        fourPoolsToSemiLoser(matches_by_weight(w))
      end
    end
  end

  def matches_by_weight(weight)
    matches.where(weight_id: weight.id)
  end

  def twoPoolsToSemiLoser(matches_by_weight)
    match1 = matches_by_weight.select{|m| m.loser1_name == "Winner Pool 1"}.first
    match2 = matches_by_weight.select{|m| m.loser1_name == "Winner Pool 2"}.first
    matchChange = matches_by_weight.select{|m| m.bracket_position == "3/4"}.first
    matchChange.loser1_name = "Loser of #{match1}"
    matchChange.loser2_name = "Loser of #{match2}"
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
    bracket_matches = group.select do |m|
      m.bracket_position_number == bracket_position
    end
    bracket_matches.first.bout_number
  end

  def fourPoolsToQuarterLoser(matches_by_weight)
    quarters = matches_by_weight.select{|m| m.bracket_position == "Quarter"}
    consoSemis = matches_by_weight.select{|m| m.bracket_position == "Conso Semis"}
    semis = matches_by_weight.select{|m| m.bracket_position == "Semis"}
    thirdFourth = matches_by_weight.select{|m| m.bracket_position == "3/4"}.first
    seventhEighth = matches_by_weight.select{|m| m.bracket_position == "7/8"}.first
    consoSemis.each do |m|
      if m.bracket_position_number == 1
        updateLosers(m, quarters, 1, 2)
      elsif m.bracket_position_number == 2
        updateLosers(m, quarters, 3, 4)
      end
    end
    updateLosers(thirdFourth, semis, 1, 2)
    consoSemis = matches_by_weight.select{|m| m.bracket_position == "Conso Semis"}
    updateLosers(seventhEighth, consoSemis, 1, 2)
  end

  def fourPoolsToSemiLoser(matches_by_weight)
    semis = matches_by_weight.select{|m| m.bracket_position == "Semis"}
    thirdFourth = matches_by_weight.select{|m| m.bracket_position == "3/4"}.first
    consoSemis = matches_by_weight.select{|m| m.bracket_position == "Conso Semis"}
    seventhEighth = matches_by_weight.select{|m| m.bracket_position == "7/8"}.first
    updateLosers(thirdFourth, semis, 1, 2)
    updateLosers(seventhEighth, consoSemis, 1, 2)
  end

end
