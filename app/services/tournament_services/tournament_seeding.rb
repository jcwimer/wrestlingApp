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
		first_line_of_second_half_of_bracket = half_of_bracket + 1
		second_half_available_bracket_lines = (first_line_of_second_half_of_bracket..bracket_size).to_a

		# remove bracket lines that are taken from available_bracket_lines
		wrestlers_with_bracket_lines = wrestlers.select{|w| w.bracket_line != nil }
		wrestlers_with_bracket_lines.each do |wrestler|
			available_bracket_lines.delete(wrestler.bracket_line)
			first_half_available_bracket_lines.delete(wrestler.bracket_line)
			second_half_available_bracket_lines.delete(wrestler.bracket_line)
		end

		available_bracket_lines_to_use = set_random_seeding_bracket_line_order(first_half_available_bracket_lines, second_half_available_bracket_lines)

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
				if available_bracket_lines_to_use.size > 0
					bracket_line_to_use = available_bracket_lines_to_use.first
					wrestler.bracket_line = bracket_line_to_use
					available_bracket_lines_to_use.delete(bracket_line_to_use)
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

	private

	def set_random_seeding_bracket_line_order(first_half_lines, second_half_lines)
		# This method prevents double BYEs in round 1
		# It also evenly distributes matches from the top half of the bracket to the bottom half
		# It does both of these while keeping the randomness of the line assignment
		odd_or_even = [0, 1]
		odd_or_even_sample = odd_or_even.sample

		# sort by odd or even based on the sample above
		if odd_or_even_sample == 1
			# odd numbers first
			sorted_first_half_lines = first_half_lines.sort_by { |n| n.even? ? 1 : 0 }
			sorted_second_half_lines = second_half_lines.sort_by { |n| n.even? ? 1 : 0 }
		else
			# even numbers first
			sorted_first_half_lines = first_half_lines.sort_by { |n| n.odd? ? 1 : 0 }
			sorted_second_half_lines = second_half_lines.sort_by { |n| n.odd? ? 1 : 0 }
		end

		# zip requires either even arrays or the receiver to be the bigger list
		if first_half_lines.size >= second_half_lines.size
			result = sorted_first_half_lines.zip(sorted_second_half_lines).flatten
		else
			result = sorted_second_half_lines.zip(sorted_first_half_lines).flatten
		end
		result.compact
		result.delete(nil)
		result
	end
end