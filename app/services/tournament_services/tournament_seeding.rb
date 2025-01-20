class TournamentSeeding
    def initialize( tournament )
      @tournament = tournament
    end
    
    def set_seeds
        @tournament.weights.each do |weight|
			wrestlers = weight.wrestlers
			bracket_size = weight.calculate_bracket_size

            wrestlers = reset_bracket_line_for_lines_higher_than_bracket_size(wrestlers, bracket_size)
            wrestlers = set_original_seed_to_bracket_line(wrestlers)
            wrestlers = random_seeding(wrestlers, bracket_size)
			wrestlers.each(&:save)
        end
    end
    
    def random_seeding(wrestlers, bracket_size)
		half_of_bracket = bracket_size / 2
		available_bracket_lines = (1..bracket_size).to_a
		first_half_available_bracket_lines = (1..half_of_bracket).to_a

		# remove bracket lines that are taken from available_bracket_lines
		wrestlers_with_bracket_lines = wrestlers.select{|w| w.bracket_line != nil }
		wrestlers_with_bracket_lines.each do |wrestler|
			available_bracket_lines.delete(wrestler.bracket_line)
			first_half_available_bracket_lines.delete(wrestler.bracket_line)
		end

		wrestlers_without_bracket_lines = wrestlers.select{|w| w.bracket_line == nil }
		if @tournament.tournament_type == "Pool to bracket"
			wrestlers_without_bracket_lines.shuffle.each do |wrestler|
				# pool brackets just grab the first available seed
				first_available_bracket_line = available_bracket_lines.first
				wrestler.bracket_line = first_available_bracket_line
				available_bracket_lines.delete(first_available_bracket_line)
			end
		else
			# Iterrate over the list randomly
			wrestlers_without_bracket_lines.shuffle.each do |wrestler|
				if first_half_available_bracket_lines.size > 0
					random_available_bracket_line = first_half_available_bracket_lines.sample
					wrestler.bracket_line = random_available_bracket_line
					available_bracket_lines.delete(random_available_bracket_line)
					first_half_available_bracket_lines.delete(random_available_bracket_line)
				else
					random_available_bracket_line = available_bracket_lines.sample
					wrestler.bracket_line = random_available_bracket_line
					available_bracket_lines.delete(random_available_bracket_line)
				end
			end
		end
		return wrestlers
	end
	
	def set_original_seed_to_bracket_line(wrestlers)
		wrestlers_with_seeds = wrestlers.select{|w| w.original_seed != nil }
		wrestlers_with_seeds.each do |wrestler|
			wrestlers_with_seeded_wrestlers_bracket_line = wrestlers.select{|w| w.bracket_line == wrestler.original_seed && w.id != wrestler.id}
			wrestlers_with_seeded_wrestlers_bracket_line.each do |wrestler_with_wrong_bracket_line|
				wrestler_with_wrong_bracket_line.bracket_line = nil
			end
			
			wrestler.bracket_line = wrestler.original_seed
		end
		return wrestlers
	end
	
	def reset_bracket_line_for_lines_higher_than_bracket_size(wrestlers, bracket_size)
		wrestlers.each do |w|
			if w.bracket_line && w.bracket_line > bracket_size
				w.bracket_line = nil
			end
		end
		return wrestlers
	end

	def reset_all_seeds(wrestlers)
		wrestlers.each do |w|
			w.bracket_line = nil
		end
		return wrestlers
	end
end