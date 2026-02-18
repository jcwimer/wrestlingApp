class Mat < ApplicationRecord
	include ActionView::RecordIdentifier
	belongs_to :tournament
	has_many :matches, dependent: :nullify
	has_many :mat_assignment_rules, dependent: :destroy

	validates :name, presence: true

	QUEUE_SLOTS = %w[queue1 queue2 queue3 queue4].freeze

	after_save :clear_queue_matches_cache

	def assign_next_match
		slot = first_empty_queue_slot
		return true unless slot

		match = next_eligible_match
		return false unless match

		place_match_in_empty_slot!(match, slot)
		true
	end

	def advance_queue!(finished_match = nil)
		self.class.transaction do
			if finished_match
				position = queue_position_for_match(finished_match)
				if position == 1
					shift_queue_forward!
					fill_queue_slots!
				elsif position
					remove_match_from_queue_and_collapse!(finished_match.id)
				else
					fill_queue_slots!
				end
			else
				if queue1_match&.finished == 1
					shift_queue_forward!
				end
				fill_queue_slots!
			end
		end
		broadcast_current_match
		true
	end

	def next_eligible_match
		# Start with all matches that are either unfinished (nil or 0), have a bout number, and are ordered by bout_number
		filtered_matches = Match.where(tournament_id: tournament_id)
									  .where(finished: [nil, 0])  # finished is nil or 0
									  .where(mat_id: nil)         # mat_id is nil
									  .where.not(bout_number: nil) # bout_number is not nil
									  .order(:bout_number)
	  
		# Filter out BYE matches
		filtered_matches = filtered_matches
							.where("loser1_name != ? OR loser1_name IS NULL", "BYE")
							.where("loser2_name != ? OR loser2_name IS NULL", "BYE")

		# Filter out matches without a wrestlers
		filtered_matches = filtered_matches
							.where("w1 IS NOT NULL")
							.where("w2 IS NOT NULL")
	  
		# Apply mat assignment rules
		mat_assignment_rules.each do |rule|
		  if rule.weight_classes.any?
			# Ensure weight_classes is treated as an array
			filtered_matches = filtered_matches.where(weight_id: Array(rule.weight_classes).map(&:to_i))
		  end
	  
		  if rule.bracket_positions.any?
			# Ensure bracket_positions is treated as an array
			filtered_matches = filtered_matches.where(bracket_position: Array(rule.bracket_positions).map(&:to_s))
		  end
	  
		  if rule.rounds.any?
			# Ensure rounds is treated as an array
			filtered_matches = filtered_matches.where(round: Array(rule.rounds).map(&:to_i))
		  end
		end
	  
		# Return the first match in filtered results, or nil if none are left
		filtered_matches.first
	end			
	  
	def queue_match_ids
		QUEUE_SLOTS.map { |slot| public_send(slot) }
	end

	# used to prevent N+1 query on each mat
	def queue_matches
		slot_ids = queue_match_ids
		if @queue_matches.nil? || @queue_match_slot_ids != slot_ids
			ids = slot_ids.compact
			@queue_matches = if ids.empty?
				[nil, nil, nil, nil]
			else
				matches_by_id = Match.where(id: ids)
								 .includes({ wrestler1: :school }, { wrestler2: :school }, { weight: :matches })
								 .index_by(&:id)
				slot_ids.map { |match_id| match_id ? matches_by_id[match_id] : nil }
			end
			@queue_match_slot_ids = slot_ids
		end
		@queue_matches
	end

	def queue1_match
		queue_match_at(1)
	end

	def queue2_match
		queue_match_at(2)
	end

	def queue3_match
		queue_match_at(3)
	end

	def queue4_match
		queue_match_at(4)
	end

	def queue_position_for_match(match)
		return nil unless match
		return 1 if queue1 == match.id
		return 2 if queue2 == match.id
		return 3 if queue3 == match.id
		return 4 if queue4 == match.id
		nil
	end

	def remove_match_from_queue_and_collapse!(match_id)
		queue_ids = queue_match_ids
		return if queue_ids.none? { |id| id == match_id }

		queue_ids.map! { |id| id == match_id ? nil : id }
		queue_ids = queue_ids.compact
		queue_ids += [nil] * (4 - queue_ids.size)

		update!(
			queue1: queue_ids[0],
			queue2: queue_ids[1],
			queue3: queue_ids[2],
			queue4: queue_ids[3]
		)

		fill_queue_slots!
		broadcast_current_match
	end

	def assign_match_to_queue!(match, position)
		position = position.to_i
		raise ArgumentError, "Queue position must be 1-4" unless (1..4).cover?(position)

		self.class.transaction do
			match.update!(mat_id: id)
			remove_match_from_other_mats!(match.id)

			queue_ids = queue_match_ids.map { |id| id == match.id ? nil : id }
			queue_ids = queue_ids.compact

			queue_ids.insert(position - 1, match.id)
			bumped_match_id = queue_ids.length > 4 ? queue_ids.pop : nil

			queue_ids += [nil] * (4 - queue_ids.length)

			update!(
				queue1: queue_ids[0],
				queue2: queue_ids[1],
				queue3: queue_ids[2],
				queue4: queue_ids[3]
			)

			bumped_match = Match.find_by(id: bumped_match_id)
			if bumped_match && bumped_match.finished != 1
				bumped_match.update!(mat_id: nil)
			end
		end
		broadcast_current_match
	end

	def clear_queue!
		update!(queue1: nil, queue2: nil, queue3: nil, queue4: nil)
	end

	def unfinished_matches
		matches.select{|m| m.finished != 1}.sort_by{|m| m.bout_number}
	end

	private

	def clear_queue_matches_cache
		@queue_matches = nil
		@queue_match_slot_ids = nil
	end

	def queue_match_at(position)
		queue_matches[position - 1]
	end

	def first_empty_queue_slot
		QUEUE_SLOTS.each_with_index do |slot, index|
			return index + 1 if public_send(slot).nil?
		end
		nil
	end

	def shift_queue_forward!
		update!(
			queue1: queue2,
			queue2: queue3,
			queue3: queue4,
			queue4: nil
		)
	end

	def fill_queue_slots!
		queue_ids = queue_match_ids
		updated = false

		QUEUE_SLOTS.each_with_index do |_slot, index|
			next if queue_ids[index].present?

			match = next_eligible_match
			break unless match

			queue_ids[index] = match.id
			match.update!(mat_id: id)
			updated = true
		end

		if updated
			update!(
				queue1: queue_ids[0],
				queue2: queue_ids[1],
				queue3: queue_ids[2],
				queue4: queue_ids[3]
			)
		end
	end

	def remove_match_from_other_mats!(match_id)
		self.class.where.not(id: id)
				  .where("queue1 = :match_id OR queue2 = :match_id OR queue3 = :match_id OR queue4 = :match_id", match_id: match_id)
				  .find_each do |mat|
			mat.remove_match_from_queue_and_collapse!(match_id)
		end
	end

	def place_match_in_empty_slot!(match, slot)
		self.class.transaction do
			match.update!(mat_id: id)
			remove_match_from_other_mats!(match.id)
			update!(slot_key(slot) => match.id)
		end
		broadcast_current_match
	end

	def slot_key(slot)
		"queue#{slot}"
	end

	def broadcast_current_match
		Turbo::StreamsChannel.broadcast_update_to(
			self,
			target: dom_id(self, :current_match),
			partial: "mats/current_match",
			locals: {
				mat: self,
				match: queue1_match,
				next_match: queue2_match,
				show_next_bout_button: true
			}
		)
	end

end
