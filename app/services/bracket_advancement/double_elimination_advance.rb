# frozen_string_literal: true

module BracketAdvancement
  class DoubleEliminationAdvance
    attr_reader :matches_to_advance

    def initialize(wrestler, last_match, matches: nil)
      @wrestler = wrestler
      @last_match = last_match
      @matches = matches || @wrestler.weight.matches.to_a
      @matches_to_advance = []
      @next_match_position_number = (@last_match.bracket_position_number / 2.0)
    end

    def bracket_advancement
      advance_wrestler
      advance_double_byes
      set_bye_for_placement
    end

    def advance_wrestler
      # Advance winner
      if @last_match.winner == @wrestler
        winners_bracket_advancement
      # Advance loser
      elsif @last_match.winner != @wrestler
        losers_bracket_advancement
      end
    end

    def winners_bracket_advancement
      update_consolation_bye if ((@last_match.loser1_name == 'BYE') || (@last_match.loser2_name == 'BYE')) && @last_match.championship_match?

      future_round_matches = @last_match.weight.matches.select { |m| m.round > @last_match.round }
      next_match = nil
      next_match_bracket_position = nil
      next_match_position_number = @next_match_position_number.ceil

      if @last_match.championship_match? && future_round_matches.size.positive?
        future_round_matches.select(&:championship_match?).min_by(&:round).round
        next_match_bracket_position = future_round_matches.select(&:championship_match?).min_by(&:round).bracket_position
      end

      if @last_match.consolation_match? && future_round_matches.size.positive?
        future_round_matches.select(&:consolation_match?).min_by(&:round).round
        next_match_bracket_position = future_round_matches.select(&:consolation_match?).min_by(&:round).bracket_position
        next_match_loser1_name = future_round_matches.select(&:consolation_match?).min_by(&:round).loser1_name
        # If someone is falling down to them in this round, then their bracket_position_number stays the same
        next_match_position_number = @last_match.bracket_position_number if next_match_loser1_name
      end

      if next_match_bracket_position
        next_match = @matches.find do |m|
          m.bracket_position == next_match_bracket_position &&
            m.bracket_position_number == next_match_position_number.ceil &&
            m.weight_id == @wrestler.weight_id
        end
      end

      return unless next_match

      update_new_match(next_match, wrestler_number)
    end

    def update_new_match(match, wrestler_number)
      if (wrestler_number == 2) || match.loser1_name&.include?('Loser of')
        match.w2 = @wrestler.id
      elsif wrestler_number == 1
        match.w1 = @wrestler.id
      end
    end

    def update_consolation_bye
      bout = @wrestler.last_match.bout_number
      next_match = @matches.find do |m|
        m.weight_id == @wrestler.weight_id && (m.loser1_name == "Loser of #{bout}" || m.loser2_name == "Loser of #{bout}")
      end
      return unless next_match

      replace_loser_name_with_bye(next_match, "Loser of #{bout}")
    end

    def wrestler_number
      if @next_match_position_number != @next_match_position_number.ceil
        1
      elsif @next_match_position_number == @next_match_position_number.ceil
        2
      end
    end

    def losers_bracket_advancement
      bout = @last_match.bout_number
      next_match = @matches.find do |m|
        m.weight_id == @wrestler.weight_id && (m.loser1_name == "Loser of #{bout}" || m.loser2_name == "Loser of #{bout}")
      end

      return if next_match.blank?

      replace_loser_name_with_wrestler(next_match, @wrestler, "Loser of #{bout}")

      return unless next_match.loser1_name == 'BYE' || next_match.loser2_name == 'BYE'

      next_match.winner_id = @wrestler.id
      next_match.win_type = 'BYE'
      next_match.score = ''
      next_match.finished = 1
      next_match.finished_at = Time.current
      @matches_to_advance << next_match
    end

    def advance_double_byes
      weight = @wrestler.weight
      @matches.select do |m|
        m.weight_id == weight.id && m.loser1_name == 'BYE' and m.loser2_name == 'BYE' and m.finished != 1
      end.each do |match|
        match.finished = 1
        match.finished_at = Time.current
        match.score = ''
        match.win_type = 'BYE'
        next_match_position_number = (match.bracket_position_number / 2.0).ceil
        after_matches = @matches.select do |m|
          m.weight_id == weight.id && m.round > match.round and m.consolation_match? == match.consolation_match?
        end.sort_by(&:round)
        next if after_matches.empty?

        next_matches = @matches.select do |m|
          m.weight_id == weight.id && m.round == after_matches.first.round and m.consolation_match? == match.consolation_match?
        end
        this_round_matches = @matches.select do |m|
          m.weight_id == weight.id && m.round == match.round and m.consolation_match? == match.consolation_match?
        end
        next_match = nil

        if next_matches.size == this_round_matches.size
          next_match = next_matches.find { |m| m.bracket_position_number == match.bracket_position_number }
          next_match.loser2_name = 'BYE' if next_match
        elsif (next_matches.size < this_round_matches.size) && next_matches.size.positive?
          next_match = next_matches.find { |m| m.bracket_position_number == next_match_position_number }
          if next_match && next_match.bracket_position_number == next_match_position_number
            next_match.loser2_name = 'BYE'
          elsif next_match
            next_match.loser1_name = 'BYE'
          end
        end
      end
    end

    def set_bye_for_placement
      weight = @wrestler.weight
      fifth_finals = @matches.find { |match| match.weight_id == weight.id && match.bracket_position == '5/6' }
      seventh_finals = @matches.find { |match| match.weight_id == weight.id && match.bracket_position == '7/8' }
      if seventh_finals
        conso_quarter = @matches.select do |match|
          match.weight_id == weight.id && match.bracket_position == 'Conso Quarter'
        end
        conso_quarter.each do |match|
          replace_loser_name_with_bye(seventh_finals, "Loser of #{match.bout_number}") if (match.loser1_name == 'BYE') || (match.loser2_name == 'BYE')
        end
      end
      return unless fifth_finals

      conso_semis = @matches.select { |match| match.weight_id == weight.id && match.bracket_position == 'Conso Semis' }
      conso_semis.each do |match|
        replace_loser_name_with_bye(fifth_finals, "Loser of #{match.bout_number}") if (match.loser1_name == 'BYE') || (match.loser2_name == 'BYE')
      end
    end

    def replace_loser_name_with_wrestler(match, wrestler, loser_name)
      match.w1 = wrestler.id if match.loser1_name == loser_name
      return unless match.loser2_name == loser_name

      match.w2 = wrestler.id
    end

    def replace_loser_name_with_bye(match, loser_name)
      match.loser1_name = 'BYE' if match.loser1_name == loser_name
      return unless match.loser2_name == loser_name

      match.loser2_name = 'BYE'
    end
  end
end
