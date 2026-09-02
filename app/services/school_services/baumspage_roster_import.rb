class BaumspageRosterImport
  def initialize( school, import_text )
      @school = school
      @import_text = import_text
      @tournament = school.tournament
      @weights_by_max = @tournament.weights.index_by { |weight| weight.max.to_f.to_i.to_s }
  end

  def import_roster
    @tournament.destroy_all_matches
    wrestler_ids = @school.wrestler_ids
    Teampointadjust.where(wrestler_id: wrestler_ids).delete_all
    Wrestler.where(id: wrestler_ids).delete_all
    parse_import_text
  end

  def parse_import_text
    extra = false
    @import_text.each_line do |line|
      if line !~ /Extra Wrestlers/
      	if extra == false
      	  parse_starter(line)
        else
          parse_extra(line)
        end
      else
      	extra = true
      end
    end
  end

  def parse_starter(line)
  	extra = false
    # ,-1 allows the last field in split to be blank
    wrestler_array = line.split(',',-1)
    wrestler_losses_array_spot = wrestler_array.size - 1
    wrestler_wins_array_spot = wrestler_array.size - 2
    last_criteria_array_spot = wrestler_wins_array_spot - 1
    wrestler_criteria = ""
    (4..last_criteria_array_spot).each do |criteria_line|
      wrestler_criteria = wrestler_criteria + ", " + wrestler_array[criteria_line]
    end
    if wrestler_array[1]
      create_wrestler("#{wrestler_array[2]} #{wrestler_array[1]}", "#{wrestler_array[0]}", "#{wrestler_criteria}", "#{wrestler_array[wrestler_wins_array_spot]}", "#{wrestler_array[wrestler_losses_array_spot]}",extra)
    end
  end

  def parse_extra(line)
  	extra = true
    # ,-1 allows the last field in split to be blank
    wrestler_array = line.split(',',-1)
    wrestler_losses_array_spot = wrestler_array.size - 1
    wrestler_wins_array_spot = wrestler_array.size - 2
    if wrestler_array[1]
      create_wrestler("#{wrestler_array[2]} #{wrestler_array[1]}", "#{wrestler_array[0]}", "", "#{wrestler_array[wrestler_wins_array_spot]}", "#{wrestler_array[wrestler_losses_array_spot]}",extra)
    end
  end

  def create_wrestler(name,weight,criteria,season_win,season_loss,extra)
    if season_win == ""
      season_win = 0
    end
    if season_loss == ""
      season_loss = 0
    end
    Wrestler.new(
      name: name,
      school: @school,
      weight: @weights_by_max.fetch(weight.to_f.to_i.to_s),
      criteria: criteria,
      season_win: season_win,
      season_loss: season_loss,
      extra: extra
    ).save
  end
end
