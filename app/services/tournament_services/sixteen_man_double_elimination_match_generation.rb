class SixteenManDoubleEliminationMatchGeneration
    def initialize( tournament )
      @tournament = tournament
    end

    def generate_matches
      @tournament.weights.each do |weight|
      	generate_matches_for_weight(weight)
      end
    end

    def generate_matches_for_weight(weight)
      round_one(weight)
      round_two(weight)
      round_three(weight)
      round_four(weight)
      round_five(weight)
      round_six(weight)
    end

    def round_one(weight)
      create_matchup_from_seed(1,16, "Bracket", 1, 1,weight)
      create_matchup_from_seed(8,9, "Bracket", 2, 1,weight)
      create_matchup_from_seed(5,12, "Bracket", 3, 1,weight)
      create_matchup_from_seed(4,14, "Bracket", 4, 1,weight)
      create_matchup_from_seed(3,13, "Bracket", 5, 1,weight)
      create_matchup_from_seed(6,11, "Bracket", 6, 1,weight)
      create_matchup_from_seed(7,10, "Bracket", 7, 1,weight)
      create_matchup_from_seed(2,15, "Bracket", 8, 1,weight)
    end

    def round_two(weight)
      create_matchup(nil,nil,"Quarter",1,2,weight)
      create_matchup(nil,nil,"Quarter",2,2,weight)
      create_matchup(nil,nil,"Quarter",3,2,weight)
      create_matchup(nil,nil,"Quarter",4,2,weight)
      create_matchup(nil,nil,"Conso",1,2,weight)
      create_matchup(nil,nil,"Conso",2,2,weight)
      create_matchup(nil,nil,"Conso",3,2,weight)
      create_matchup(nil,nil,"Conso",4,2,weight)
    end

    def round_three(weight)
      create_matchup(nil,nil,"Conso",1,3,weight)
      create_matchup(nil,nil,"Conso",2,3,weight)
      create_matchup(nil,nil,"Conso",3,3,weight)
      create_matchup(nil,nil,"Conso",4,3,weight)
    end

    def round_four(weight)
      create_matchup(nil,nil,"Semis",1,4,weight)
      create_matchup(nil,nil,"Semis",2,4,weight)
      create_matchup(nil,nil,"Conso Quarter",1,4,weight)
      create_matchup(nil,nil,"Conso Quarter",2,4,weight)
    end

    def round_five(weight)
      create_matchup(nil,nil,"Conso Semis",1,5,weight)
      create_matchup(nil,nil,"Conso Semis",2,5,weight)
    end

    def round_six(weight)
      create_matchup(nil,nil,"1/2",1,6,weight)
      create_matchup(nil,nil,"3/4",1,6,weight)
      create_matchup(nil,nil,"5/6",1,6,weight)
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
        @tournament.matches.create(
          w1: w1,
          w2: w2,
          weight_id: weight.id,
          round: round,
          bracket_position: bracket_position,
          bracket_position_number: bracket_position_number
        )
    end
end