module GeneratesLoserNames
  def assignLoserNames
    matches_by_weight = nil
    weights.each do |w|
      matches_by_weight = matches.where(weight_id: w.id)
      if w.pool_bracket_type == "twoPoolsToSemi"
        twoPoolsToSemiLoser(matches_by_weight)
      elsif w.pool_bracket_type == "fourPoolsToQuarter"
        fourPoolsToQuarterLoser(matches_by_weight)
      elsif w.pool_bracket_type == "fourPoolsToSemi"
        fourPoolsToSemiLoser(matches_by_weight)
      end
      saveMatches(matches_by_weight)
    end
  end

  def twoPoolsToSemiLoser(matches_by_weight)
    match1 = matches_by_weight.select{|m| m.loser1_name == "Winner Pool 1"}.first
    match2 = matches_by_weight.select{|m| m.loser1_name == "Winner Pool 2"}.first
    matchChange = matches_by_weight.select{|m| m.bracket_position == "3/4"}.first
    matchChange.loser1_name = "Loser of #{match1.bout_number}"
    matchChange.loser2_name = "Loser of #{match2.bout_number}"
  end

  def fourPoolsToQuarterLoser(matches_by_weight)
    quarters = matches_by_weight.select{|m| m.bracket_position == "Quarter"}
    consoSemis = matches_by_weight.select{|m| m.bracket_position == "Conso Semis"}
    semis = matches_by_weight.select{|m| m.bracket_position == "Semis"}
    thirdFourth = matches_by_weight.select{|m| m.bracket_position == "3/4"}.first
    seventhEighth = matches_by_weight.select{|m| m.bracket_position == "7/8"}.first
    consoSemis.each do |m|
      if m.bracket_position_number == 1
        m.loser1_name = "Loser of #{quarters.select{|m| m.bracket_position_number == 1}.first.bout_number}"
        m.loser2_name = "Loser of #{quarters.select{|m| m.bracket_position_number == 2}.first.bout_number}"
      elsif m.bracket_position_number == 2
        m.loser1_name = "Loser of #{quarters.select{|m| m.bracket_position_number == 3}.first.bout_number}"
        m.loser2_name = "Loser of #{quarters.select{|m| m.bracket_position_number == 4}.first.bout_number}"
      end
    end
    thirdFourth.loser1_name = "Loser of #{semis.select{|m| m.bracket_position_number == 1}.first.bout_number}"
    thirdFourth.loser2_name = "Loser of #{semis.select{|m| m.bracket_position_number == 2}.first.bout_number}"
    consoSemis = matches_by_weight.select{|m| m.bracket_position == "Conso Semis"}
    seventhEighth.loser1_name = "Loser of #{consoSemis.select{|m| m.bracket_position_number == 1}.first.bout_number}"
    seventhEighth.loser2_name = "Loser of #{consoSemis.select{|m| m.bracket_position_number == 2}.first.bout_number}"
  end

  def fourPoolsToSemiLoser(matches_by_weight)
    semis = matches_by_weight.select{|m| m.bracket_position == "Semis"}
    thirdFourth = matches_by_weight.select{|m| m.bracket_position == "3/4"}.first
    consoSemis = matches_by_weight.select{|m| m.bracket_position == "Conso Semis"}
    seventhEighth = matches_by_weight.select{|m| m.bracket_position == "7/8"}.first
    thirdFourth.loser1_name = "Loser of #{semis.select{|m| m.bracket_position_number == 1}.first.bout_number}"
    thirdFourth.loser2_name = "Loser of #{semis.select{|m| m.bracket_position_number == 2}.first.bout_number}"
    seventhEighth.loser1_name = "Loser of #{consoSemis.select{|m| m.bracket_position_number == 1}.first.bout_number}"
    seventhEighth.loser2_name = "Loser of #{consoSemis.select{|m| m.bracket_position_number == 2}.first.bout_number}"
  end
  
  def saveMatches(matches)
      matches.each do |m|
        m.save!
      end
  end
end
