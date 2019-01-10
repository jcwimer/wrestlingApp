class BaumspageRosterImport
  def initialize( school, import_text )
      @school = school
      @import_text = import_text 
  end

  def import_roster
  	@school.wrestlers.each do |wrestler|
  		wrestler.destroy
  	end
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
    wrestler_array = line.split(',')
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
    wrestler_array = line.split(',')
    wrestler_losses_array_spot = wrestler_array.size - 1
    wrestler_wins_array_spot = wrestler_array.size - 2
    if wrestler_array[1]
       create_wrestler("#{wrestler_array[2]} #{wrestler_array[1]}", "#{wrestler_array[0]}", "", "#{wrestler_array[wrestler_wins_array_spot]}", "#{wrestler_array[wrestler_losses_array_spot]}",extra)
    end
  end

  def create_wrestler(name,weight,criteria,season_win,season_loss,extra)
    wrestler = Wrestler.new
    wrestler.name = name
    wrestler.school_id = @school.id
    wrestler.weight_id = Weight.where("tournament_id = ? and max = ?", @school.tournament.id, weight).first.id
    wrestler.criteria = criteria
    wrestler.season_win = season_win
    wrestler.season_loss = season_loss
    wrestler.extra = extra
    wrestler.save
  end
end