class EightManDoubleEliminationMatchGeneration
    def initialize( weight )
      @weight = weight
    end

    def generate_matches_for_weight
      round_one(@weight)
      round_two(@weight)
      round_three(@weight)
      round_four(@weight)
    end

    def round_one(weight)
      create_matchup_from_seed(1,8,"Quarter",1,1,weight)
      create_matchup_from_seed(4,5,"Quarter",2,1,weight)
      create_matchup_from_seed(3,6,"Quarter",3,1,weight)
      create_matchup_from_seed(2,7,"Quarter",4,1,weight)
    end

    def round_two(weight)
      create_matchup(nil,nil,"Semis",1,2,weight)
      create_matchup(nil,nil,"Semis",2,2,weight)
      create_matchup(nil,nil,"Conso Quarter",1,2,weight)
      create_matchup(nil,nil,"Conso Quarter",2,2,weight)
    end

    def round_three(weight)
      create_matchup(nil,nil,"Conso Semis",1,3,weight)
      create_matchup(nil,nil,"Conso Semis",2,3,weight)
    end

    def round_four(weight)
      create_matchup(nil,nil,"1/2",1,4,weight)
      create_matchup(nil,nil,"3/4",1,4,weight)
      create_matchup(nil,nil,"5/6",1,4,weight)
    end

    def wrestler_with_seed(seed,weight)
      wrestler = Wrestler.where("weight_id = ? and bracket_line = ?", weight.id, seed).first
      if wrestler
        return wrestler.id
      else
      	return nil
      end
    end

    def create_matchup_from_seed(w1_seed, w2_seed, bracket_position, bracket_position_number,round,weight)
        # if wrestler_with_seed(w1_seed,weight) and wrestler_with_seed(w2_seed,weight)
            create_matchup(wrestler_with_seed(w1_seed,weight),wrestler_with_seed(w2_seed,weight), bracket_position, bracket_position_number,round,weight)
        # end
    end

    def create_matchup(w1, w2, bracket_position, bracket_position_number,round,weight)
        @weight.tournament.matches.create(
          w1: w1,
          w2: w2,
          weight_id: weight.id,
          round: round,
          bracket_position: bracket_position,
          bracket_position_number: bracket_position_number
        )
    end
end