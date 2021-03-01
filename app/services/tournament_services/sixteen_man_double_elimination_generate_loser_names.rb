class SixteenManDoubleEliminationGenerateLoserNames
    def initialize( weight )
      @weight = weight
    end

   def assign_loser_names_for_weight
    matches_by_weight = nil
    matches_by_weight = @weight.matches
    conso_round_2(matches_by_weight)
    conso_round_3(matches_by_weight)
    conso_round_5(matches_by_weight)
    fifth_sixth(matches_by_weight)
    seventh_eighth(matches_by_weight)
    save_matches(matches_by_weight)
    matches_by_weight = @weight.matches.reload
    advance_bye_matches_championship(matches_by_weight)
    save_matches(matches_by_weight)
   end

   def conso_round_2(matches)
     matches.select{|m| m.round == 2 and m.bracket_position == "Conso"}.sort_by{|m| m.bracket_position_number}.each do |match|
        if match.bracket_position_number == 1
          match.loser1_name = "Loser of #{matches.select{|m| m.bracket_position_number == 1 and m.round == 1 and m.bracket_position == "Bracket"}.first.bout_number}"
          match.loser2_name = "Loser of #{matches.select{|m| m.bracket_position_number == 2 and m.round == 1 and m.bracket_position == "Bracket"}.first.bout_number}"
        elsif match.bracket_position_number == 2
          match.loser1_name = "Loser of #{matches.select{|m| m.bracket_position_number == 3 and m.round == 1 and m.bracket_position == "Bracket"}.first.bout_number}"
          match.loser2_name = "Loser of #{matches.select{|m| m.bracket_position_number == 4 and m.round == 1 and m.bracket_position == "Bracket"}.first.bout_number}"
        elsif match.bracket_position_number == 3
          match.loser1_name = "Loser of #{matches.select{|m| m.bracket_position_number == 5 and m.round == 1 and m.bracket_position == "Bracket"}.first.bout_number}"
          match.loser2_name = "Loser of #{matches.select{|m| m.bracket_position_number == 6 and m.round == 1 and m.bracket_position == "Bracket"}.first.bout_number}"
        elsif match.bracket_position_number == 4
          match.loser1_name = "Loser of #{matches.select{|m| m.bracket_position_number == 7 and m.round == 1 and m.bracket_position == "Bracket"}.first.bout_number}"
          match.loser2_name = "Loser of #{matches.select{|m| m.bracket_position_number == 8 and m.round == 1 and m.bracket_position == "Bracket"}.first.bout_number}"
        end
      end
   end

   def conso_round_3(matches)
     matches.select{|m| m.round == 3 and m.bracket_position == "Conso"}.sort_by{|m| m.bracket_position_number}.each do |match|
        if match.bracket_position_number == 1
          match.loser1_name = "Loser of #{matches.select{|m| m.bracket_position_number == 4 and m.bracket_position == "Quarter"}.first.bout_number}"
        elsif match.bracket_position_number == 2
          match.loser1_name = "Loser of #{matches.select{|m| m.bracket_position_number == 3 and m.bracket_position == "Quarter"}.first.bout_number}"
        elsif match.bracket_position_number == 3
          match.loser1_name = "Loser of #{matches.select{|m| m.bracket_position_number == 2 and m.bracket_position == "Quarter"}.first.bout_number}"
        elsif match.bracket_position_number == 4
          match.loser1_name = "Loser of #{matches.select{|m| m.bracket_position_number == 1 and m.bracket_position == "Quarter"}.first.bout_number}"
        end
      end
   end

   def conso_round_5(matches)
     matches.select{|m| m.round == 5 and m.bracket_position == "Conso Semis"}.sort_by{|m| m.bracket_position_number}.each do |match|
        if match.bracket_position_number == 1
          match.loser1_name = "Loser of #{matches.select{|m| m.bracket_position_number == 1 and m.bracket_position == "Semis"}.first.bout_number}"
        elsif match.bracket_position_number == 2
          match.loser1_name = "Loser of #{matches.select{|m| m.bracket_position_number == 2 and m.bracket_position == "Semis"}.first.bout_number}"
        end
      end
   end

   def fifth_sixth(matches)
     matches.select{|m| m.bracket_position == "5/6"}.sort_by{|m| m.bracket_position_number}.each do |match|
          match.loser1_name = "Loser of #{matches.select{|m| m.bracket_position == "Conso Semis"}.first.bout_number}"
          match.loser2_name = "Loser of #{matches.select{|m| m.bracket_position == "Conso Semis"}.second.bout_number}"
      end
   end
   
   def seventh_eighth(matches)
     matches.select{|m| m.bracket_position == "7/8"}.sort_by{|m| m.bracket_position_number}.each do |match|
          match.loser1_name = "Loser of #{matches.select{|m| m.bracket_position == "Conso Quarter"}.first.bout_number}"
          match.loser2_name = "Loser of #{matches.select{|m| m.bracket_position == "Conso Quarter"}.second.bout_number}"
      end
   end

   def advance_bye_matches_championship(matches)
      matches.select{|m| m.round == 1 and m.bracket_position == "Bracket"}.sort_by{|m| m.bracket_position_number}.each do |match|
        if match.w1 == nil or match.w2 == nil
          match.finished = 1
          match.win_type = "BYE"
          if match.w1 != nil
            match.winner_id = match.w1
            match.loser2_name = "BYE"
            match.save
            match.advance_wrestlers
          elsif match.w2 != nil
            match.winner_id = match.w2
            match.loser1_name = "BYE"
            match.save
            match.advance_wrestlers
          end
        end
      end
   end
  
  def save_matches(matches)
      matches.each do |m|
        m.save!
      end
  end 
    
end