class PoolAdvance

 attr_reader :matches_to_advance

 def initialize(wrestler, last_match, matches: nil, wrestlers: nil)
		@wrestler = wrestler
		@last_match = last_match
    @matches = matches || @wrestler.weight.matches.to_a
    @wrestlers = wrestlers || @wrestler.weight.wrestlers.to_a
    @matches_to_advance = []
 end

 def advanceWrestler
   if @wrestler.weight.pools > 1 and @wrestler.finished_bracket_matches.size < 1
     poolToBracketAdvancment
   end
   if @wrestler.finished_bracket_matches.size > 0
	    bracketAdvancment
   end
 end

 def poolToBracketAdvancment
    pool = @wrestler.pool
    # This has to always run because the last match in a pool might not be a pool winner or runner up
    winner = @wrestlers.find { |w| w.weight_id == @wrestler.weight.id && w.pool_placement == 1 && w.pool == pool }
    runner_up = @wrestlers.find { |w| w.weight_id == @wrestler.weight.id && w.pool_placement == 2 && w.pool == pool }
    if runner_up
      runner_up_match = @matches.find { |m| m.weight_id == @wrestler.weight.id && (m.loser1_name == "Runner Up Pool #{pool}" || m.loser2_name == "Runner Up Pool #{pool}") }
      replace_loser_name_with_wrestler(runner_up_match, runner_up, "Runner Up Pool #{pool}") if runner_up_match
    end
    if winner
      winner_match = @matches.find { |m| m.weight_id == @wrestler.weight.id && (m.loser1_name == "Winner Pool #{pool}" || m.loser2_name == "Winner Pool #{pool}") }
      replace_loser_name_with_wrestler(winner_match, winner, "Winner Pool #{pool}") if winner_match
    end
 end

 def bracketAdvancment
   advance_wrestlers
 end

 def advance_wrestlers
    # Advance winner
    if @last_match.winner == @wrestler
      winner_advance
    # Advance loser
    elsif @last_match.winner != @wrestler
      loser_advance
    end
 end

 def winner_advance
   if @wrestler.last_match.bracket_position == "Quarter"
     new_match = @matches.find { |m| m.bracket_position == "Semis" && m.bracket_position_number == @wrestler.next_match_position_number.ceil && m.weight_id == @wrestler.weight_id }
     updateNewMatch(new_match)
   end
  if @wrestler.last_match.bracket_position == "Semis"
     new_match = @matches.find { |m| m.bracket_position == "1/2" && m.bracket_position_number == @wrestler.next_match_position_number.ceil && m.weight_id == @wrestler.weight_id }
     updateNewMatch(new_match)
  end
  if @wrestler.last_match.bracket_position == "Conso Semis"
     new_match = @matches.find { |m| m.bracket_position == "5/6" && m.bracket_position_number == @wrestler.next_match_position_number.ceil && m.weight_id == @wrestler.weight_id }
     updateNewMatch(new_match)
  end

 end
 
 def updateNewMatch(match)
     return unless match
     if @wrestler.next_match_position_number == @wrestler.next_match_position_number.ceil
	      match.w2 = @wrestler.id
     end
     if @wrestler.next_match_position_number != @wrestler.next_match_position_number.ceil
	      match.w1 = @wrestler.id
     end
 end

 def loser_advance
    bout = @wrestler.last_match.bout_number
    next_match = @matches.find { |m| m.weight_id == @wrestler.weight_id && (m.loser1_name == "Loser of #{bout}" || m.loser2_name == "Loser of #{bout}") }
    if next_match
     	replace_loser_name_with_wrestler(next_match, @wrestler, "Loser of #{bout}")
    end
 end

 def replace_loser_name_with_wrestler(match, wrestler, loser_name)
    match.w1 = wrestler.id if match.loser1_name == loser_name
    match.w2 = wrestler.id if match.loser2_name == loser_name
 end
end
