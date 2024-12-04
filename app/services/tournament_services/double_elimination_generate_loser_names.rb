class DoubleEliminationGenerateLoserNames
	def initialize( tournament )
      @tournament = tournament
    end

    def assign_loser_names
      @tournament.weights.each do |weight|
        assign_loser_names_for_weight(weight)
        advance_bye_matches_championship(weight.matches.reload)
      end
    end

    def define_losername_championship_mappings(bracket_size)
      # [conso_round, conso_bracket_position, championship_round, championship_bracket_position, cross_bracket, both_wrestlers]
      # cross_bracket is true or false. crossing should happen every other round.
      # both_wrestlers defines if you're filling out loser1_name and loser2_name or just loser1_name
      # don't need to define 3/4, 5/6, or 7/8 those happen in the assign_loser_names_for_weight method
      case bracket_size
      when 8 then
        return [
          [2, "Conso Quarter", 1, "Quarter", false, true],
          [3, "Conso Semis", 2, "Semis", true, false]
        ]
      when 16 then
        return [
          [2, "Conso", 1, "Bracket", false, true],
          [3, "Conso", 2, "Quarter", true],
          [5, "Conso Semis", 4, "Semis", false]
        ]
      else
        return nil
      end
    end

    def assign_loser_names_for_weight(weight)
      number_of_placers = @tournament.number_of_placers
      bracket_size = weight.calculate_bracket_size
      matches_by_weight = weight.matches

      loser_name_championship_mappings = define_losername_championship_mappings(bracket_size)

      loser_name_championship_mappings.each do |mapping|
        conso_round = mapping[0]
        conso_bracket_position = mapping[1]
        championship_round = mapping[2]
        championship_bracket_position = mapping[3]
        cross_bracket = mapping[4]
        both_wrestlers = mapping[5]

        conso_matches = matches_by_weight.select{|match| match.round == conso_round && match.bracket_position == conso_bracket_position}.sort_by{|match| match.bracket_position_number}
        championship_matches = matches_by_weight.select{|match| match.round == championship_round && match.bracket_position == championship_bracket_position}.sort_by{|match| match.bracket_position_number}
        if cross_bracket
          conso_matches = conso_matches.reverse!
        end

        championship_bracket_position_number = 1
        conso_matches.each do |match|
          bout_number1 = championship_matches.select{|bout_match| bout_match.bracket_position_number == championship_bracket_position_number}.first.bout_number
          match.loser1_name = "Loser of #{bout_number1}"
          if both_wrestlers
            championship_bracket_position_number += 1
            bout_number2 = championship_matches.select{|bout_match| bout_match.bracket_position_number == championship_bracket_position_number}.first.bout_number
            match.loser2_name = "Loser of #{bout_number2}"
          end
          championship_bracket_position_number += 1
        end
      end

      conso_semi_matches = matches_by_weight.select{|match| match.bracket_position == "Conso Semis"}
      conso_quarter_matches = matches_by_weight.select{|match| match.bracket_position == "Conso Quarter"}
      if number_of_placers >= 6
        five_six_match = matches_by_weight.select{|match| match.bracket_position == "5/6"}.first
        bout_number1 = conso_semi_matches.select{|match| match.bracket_position_number == 1}.first.bout_number
        bout_number2 = conso_semi_matches.select{|match| match.bracket_position_number == 2}.first.bout_number
        five_six_match.loser1_name = "Loser of #{bout_number1}"
        five_six_match.loser2_name = "Loser of #{bout_number2}"
      end
      if number_of_placers >= 8
        seven_eight_match = matches_by_weight.select{|match| match.bracket_position == "7/8"}.first
        bout_number1 = conso_quarter_matches.select{|match| match.bracket_position_number == 1}.first.bout_number
        bout_number2 = conso_quarter_matches.select{|match| match.bracket_position_number == 2}.first.bout_number
        seven_eight_match.loser1_name = "Loser of #{bout_number1}"
        seven_eight_match.loser2_name = "Loser of #{bout_number2}"
      end
      save_matches(matches_by_weight)
    end

    def save_matches(matches)
      matches.each do |m|
        m.save!
      end
    end

    def advance_bye_matches_championship(matches)
      matches.select{|m| m.round == 1 and (m.bracket_position == "Bracket" or m.bracket_position == "Quarter")}.sort_by{|m| m.bracket_position_number}.each do |match|
        if match.w1 == nil or match.w2 == nil
          match.finished = 1
          match.win_type = "BYE"
          if match.w1 != nil
            match.winner_id = match.w1
            match.loser2_name = "BYE"
            match.score = ""
            match.save
            match.advance_wrestlers
          elsif match.w2 != nil
            match.winner_id = match.w2
            match.loser1_name = "BYE"
            match.score = ""
            match.save
            match.advance_wrestlers
          end
        end
      end
   end
end