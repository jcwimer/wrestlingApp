class WrestlingdevImporter
  def initialize( tournament, import_text )
      @tournament = tournament
      @import_text = import_text 
      @attribute_separator = ";;"
      @model_separator = ",,"
  end

  def import
    if Rails.env.production?
        self.delay(:job_owner_id => @tournament.id, :job_owner_type => "Importing a backup").import_raw
    else
        import_raw
    end
  end

  def import_raw
    @tournament.curently_generating_matches = 1
    @tournament.save
    destroy_all
    parse_text
    @tournament.curently_generating_matches = nil
    @tournament.save
  end

  def destroy_all
    @tournament.mats.reload.each do | mat |
      mat.destroy
    end
    @tournament.matches.each do | match |
      match.destroy
    end
    @tournament.schools.each do | school |
      school.wrestlers.each do | wrestler |
        wrestler.destroy
      end
      school.destroy
    end
    @tournament.weights.each do | weight |
      weight.destroy
    end
  end

  def parse_text
    @import_text.each_line do |line|
      line_array = line.split(@model_separator,-1)
      if line_array[0] == "--Tournament--"
        line_array.shift
        parse_tournament(line_array)
      elsif line_array[0] == "--Schools--"
        line_array.shift
        parse_schools(line_array)
      elsif line_array[0] == "--Weights--"
        line_array.shift
        parse_weights(line_array)
      elsif line_array[0] == "--Mats--"
        line_array.shift
        parse_mats(line_array)
      elsif line_array[0] == "--Wrestlers--"
        line_array.shift
        parse_wrestlers(line_array)
      elsif line_array[0] == "--Matches--"
        line_array.shift
        parse_matches(line_array)
      end
    end
  end

  def parse_tournament(tournament_attributes)
    tournament_array = tournament_attributes[0].split(@attribute_separator,-1)
    @tournament.name = tournament_array[0]
    @tournament.address = tournament_array[1]
    @tournament.director = tournament_array[2]
    @tournament.director_email = tournament_array[3]
    @tournament.tournament_type = tournament_array[4]
    @tournament.weigh_in_ref = tournament_array[5]
    @tournament.user_id = tournament_array[6]
    #@tournament.curently_generating_matches = tournament_array[7]
    @tournament.date = tournament_array[8]
    @tournament.save
  end

  def parse_wrestlers(wrestlers)
    wrestlers.each do | wrestler |
      wrestler_array = wrestler.split(@attribute_separator,-1)
      new_wrestler = Wrestler.new
      new_wrestler.name = wrestler_array[0]
      
      school_id = School.where("name = ? and tournament_id = ?",wrestler_array[1],@tournament.id).first.id
      weight_id = Weight.where("max = ? and tournament_id = ?",wrestler_array[2],@tournament.id).first.id
      new_wrestler.school_id = school_id
      new_wrestler.weight_id = weight_id

      new_wrestler.bracket_line = wrestler_array[3]
      new_wrestler.original_seed = wrestler_array[4]
      new_wrestler.season_win = wrestler_array[5]
      new_wrestler.season_loss = wrestler_array[6]
      new_wrestler.criteria = wrestler_array[7]
      new_wrestler.extra = wrestler_array[8]
      new_wrestler.offical_weight = wrestler_array[9]
      new_wrestler.pool = wrestler_array[10]
      new_wrestler.pool_placement = wrestler_array[11]
      new_wrestler.pool_placement_tiebreaker = wrestler_array[12]
      new_wrestler.save
    end
  end

  def parse_matches(matches)
    matches.each do | match |
      @tournament.reload
      @tournament.mats.reload
      match_array = match.split(@attribute_separator,-1)
      new_match = Match.new
      weight_id = Weight.where("max = ? and tournament_id = ?",match_array[10],@tournament.id).first.id
      if match_array[0].size > 0
        w1_id = Wrestler.where("name = ? and weight_id = ?",match_array[0],weight_id).first.id
      end
      if match_array[1].size > 0
        w2_id = Wrestler.where("name = ? and weight_id = ?",match_array[1],weight_id).first.id
      end
      if match_array[4].size > 0
        winner_id = Wrestler.where("name = ? and weight_id = ?",match_array[4],weight_id).first.id
      end
      if match_array[15].size > 0
        # mat_id = Mat.where("name = ? and tournament_id = ?",match_array[15],@tournament.id).first.id
      end
      new_match.w1 = w1_id if match_array[0].size > 0
      new_match.w2 = w2_id if match_array[1].size > 0
      new_match.winner_id = winner_id if match_array[4].size > 0
      new_match.w1_stat = match_array[2]
      new_match.w2_stat = match_array[3]
      new_match.win_type = match_array[5]
      new_match.score = match_array[6]
      new_match.tournament_id = @tournament.id
      new_match.round = match_array[7]
      new_match. finished = match_array[8]
      new_match.bout_number = match_array[9]
      new_match.weight_id = weight_id
      new_match.bracket_position = match_array[11]
      new_match.bracket_position_number = match_array[12]
      new_match.loser1_name = match_array[13]
      new_match.loser2_name = match_array[14]
      # new_match.mat_id = mat_id if match_array[15].size > 0
      new_match.save
    end
  end

  def parse_schools(schools)
    schools.each do | school |
      school_array = school.split(@attribute_separator,-1)
      new_school = School.new
      new_school.tournament_id = @tournament.id
      new_school.name = school_array[0]
      new_school.score = school_array[1]
      new_school.save
    end
  end

  def parse_weights(weights)
    weights.each do | weight |
      weight_array = weight.split(@attribute_separator,-1)
      new_weight = Weight.new
      new_weight.tournament_id = @tournament.id
      new_weight.max = weight_array[0]
      new_weight.save
    end
  end

  def parse_mats(mats)
    mats.each do | mat |
      mat_array = mat.split(@attribute_separator,-1)
      new_mat = Mat.new
      new_mat.tournament_id = @tournament.id
      new_mat.name = mat_array[0]
      new_mat.save
    end
  end

end