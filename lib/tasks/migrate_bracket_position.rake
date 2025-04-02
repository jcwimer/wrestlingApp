# lib/tasks/migrate_bracket_position.rake
# rake tournament:migrate_bracket_position
namespace :tournament do
  desc "Fix bracket_position for matches labeled 'Bracket' or 'Conso' in Regular and Modified Double Elimination tournaments"
  task migrate_bracket_position: :environment do

    ############################################################
    # 1) Loop over REGULAR Double Elimination Tournaments
    ############################################################
    Tournament.where("tournament_type LIKE ?", "%Regular Double Elimination%").find_each do |tournament|
      tournament.weights.each do |weight|
        # Determine bracket_size: 16-man if 9..16 wrestlers, 32-man if 17..32, otherwise skip
        bracket_size = if (9..16).cover?(weight.wrestlers.size)
                         "16-man"
                       elsif (17..32).cover?(weight.wrestlers.size)
                         "32-man"
                       else
                         "small"
                       end

        # Skip small
        next if bracket_size == "small"

        weight.matches.each do |match|
          # Only update if old bracket_position is 'Bracket' or 'Conso'
          next unless ["Bracket", "Conso"].include?(match.bracket_position)

          new_pos =
            if bracket_size == "16-man"
              determine_new_bracket_position_16_man_reg(match.round, match.bracket_position)
            else
              # bracket_size == "32-man"
              determine_new_bracket_position_32_man_reg(match.round, match.bracket_position)
            end

          # If new_pos != "Default Position", update the record
          match.update!(bracket_position: new_pos) unless new_pos == "Default Position"
        end
      end
    end

    ############################################################
    # 2) Loop over MODIFIED Double Elimination Tournaments
    ############################################################
    #   Bracket + round=1 => "Bracket Round of 16"
    #   Conso + round=2 => "Conso Round of 8"
    #   else => "Default Position"
    Tournament.where("tournament_type LIKE ?", "%Modified 16 Man Double Elimination%").find_each do |tournament|
      tournament.weights.each do |weight|
        # If not 9..16 wrestlers, skip
        next unless (9..16).cover?(weight.wrestlers.size)

        weight.matches.each do |match|
          next unless ["Bracket", "Conso"].include?(match.bracket_position)

          new_pos = determine_new_bracket_position_modified_16(match.round, match.bracket_position)

          match.update!(bracket_position: new_pos) unless new_pos == "Default Position"
        end
      end
    end
  end

  ############################################################
  # HELPER METHODS
  ############################################################

  #
  # 16-MAN REGULAR Double Elimination
  #   - bracket => round=1 => "Bracket Round of 16"
  #   - conso => round=2 => "Conso Round of 8.1", round=3 => "Conso Round of 8.2"
  #
  def determine_new_bracket_position_16_man_reg(round, old_pos)
    if old_pos == "Bracket"
      case round
      when 1 then "Bracket Round of 16"
      else
        "Default Position"
      end
    elsif old_pos == "Conso"
      case round
      when 2 then "Conso Round of 8.1"
      when 3 then "Conso Round of 8.2"
      else
        "Default Position"
      end
    else
      "Default Position"
    end
  end

  #
  # 32-MAN REGULAR Double Elimination
  #   bracket => round=1 => "Bracket Round of 32", round=2 => "Bracket Round of 16"
  #   conso => round=2 => "Conso Round of 16.1", round=3 => "Conso Round of 16.2",
  #            round=4 => "Conso Round of 8.1",   round=5 => "Conso Round of 8.2"
  #
  def determine_new_bracket_position_32_man_reg(round, old_pos)
    if old_pos == "Bracket"
      case round
      when 1 then "Bracket Round of 32"
      when 2 then "Bracket Round of 16"
      else
        "Default Position"
      end
    elsif old_pos == "Conso"
      case round
      when 2 then "Conso Round of 16.1"
      when 3 then "Conso Round of 16.2"
      when 4 then "Conso Round of 8.1"
      when 5 then "Conso Round of 8.2"
      else
        "Default Position"
      end
    else
      "Default Position"
    end
  end

  #
  # MODIFIED Double Elimination (16-man).
  #   bracket => round=1 => "Bracket Round of 16"
  #   conso => round=2 => "Conso Round of 8"
  #   else => "Default Position"
  #
  def determine_new_bracket_position_modified_16(round, old_pos)
    if old_pos == "Bracket"
      round == 1 ? "Bracket Round of 16" : "Default Position"
    elsif old_pos == "Conso"
      round == 2 ? "Conso Round of 8" : "Default Position"
    else
      "Default Position"
    end
  end
end
