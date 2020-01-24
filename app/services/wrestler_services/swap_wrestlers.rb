class SwapWrestlers
    attr_accessor :wrestler1_id, :wrestler2_id

    
    def swap_wrestlers_bracket_lines(wrestler1_id,wrestler2_id)
      w1 = Wrestler.find(wrestler1_id)
      w2 = Wrestler.find(wrestler2_id)
      w1_matches = w1.all_matches
      w2_matches = w2.all_matches
      
      #placeholder guy for w1
      w3 = Wrestler.new
      w3.weight_id = w1.weight_id
      w3.original_seed = w1.original_seed
      w3.bracket_line = w1.bracket_line
      w3.pool = w1.pool
      
      # placeholder guy for w2
      w4 = Wrestler.new
      w4.weight_id = w2.weight_id
      w4.original_seed = w2.original_seed
      w4.bracket_line = w2.bracket_line
      w4.pool = w2.pool
      
      # swap w4 line and pool to w1
      w1.bracket_line = w4.bracket_line
      w1.pool = w4.pool

     # swap w3 line and pool to w2
      w2.bracket_line = w3.bracket_line
      w2.pool = w3.pool
      
      # Swap matches
      swapWrestlerMatches(w1_matches,w1.id,w2.id)
      swapWrestlerMatches(w2_matches,w2.id,w1.id)

      w1.save
      w2.save
  end
  
  def swapWrestlerMatches(matchesToSwap,from_id,to_id)
    matchesToSwap.each do |m|
          if m.w1 == from_id
              m.w1 = to_id
          elsif m.w2 == from_id
              m.w2 = to_id
          end
          if m.winner_id == from_id
              m.winner_id = to_id
          end
          m.save
    end
  end
end