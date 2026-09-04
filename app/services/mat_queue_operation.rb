class MatQueueOperation
  def initialize(tournament)
    @tournament = tournament
  end

  def assign(match, target_mat, position)
    position = position.to_i
    raise ArgumentError, "Queue position must be 1-4" unless (1..4).cover?(position)

    affected_ids = mats_containing(match.id).pluck(:id) | [target_mat.id]
    mutate(affected_ids) do |mats|
      source_mats = mats.reject { |mat| mat.id == target_mat.id }
      source_mats.each { |mat| collapse(mat, match.id) }

      target = mats.find { |mat| mat.id == target_mat.id }
      queue = target.queue_match_ids.reject { |id| id == match.id }.compact
      queue.insert(position - 1, match.id)
      bumped_id = queue.length > 4 ? queue.pop : nil
      write_queue(target, queue)
      set_match_mat(match.id, target.id)
      fill(source_mats)
      set_match_mat(bumped_id, nil) if bumped_id && bumped_id != match.id
    end
  end

  def remove(match_id)
    affected_ids = mats_containing(match_id).pluck(:id)
    if affected_ids.empty?
      Match.where(id: match_id).update_all(mat_id: nil)
      return true
    end

    mutate(affected_ids) do |mats|
      mats.each { |mat| collapse(mat, match_id) }
      set_match_mat(match_id, nil)
      fill(mats)
    end
  end

  def clear(mat)
    mutate([mat.id]) do |mats|
      locked_mat = mats.first
      Match.where(id: locked_mat.queue_match_ids.compact, mat_id: locked_mat.id).update_all(mat_id: nil)
      write_queue(locked_mat, [])
    end
  end

  def advance(mat, finished_match = nil)
    affected_ids = @tournament.mats.pluck(:id)
    changed = false
    mutate(affected_ids) do |mats|
      locked_mat = mats.find { |candidate| candidate.id == mat.id }
      if finished_match
        changed = locked_mat.queue_match_ids.include?(finished_match.id)
        collapse(locked_mat, finished_match.id)
        set_match_mat(finished_match.id, nil)
      elsif locked_mat.queue1 && Match.where(id: locked_mat.queue1, finished: 1).exists?
        finished_id = locked_mat.queue1
        collapse(locked_mat, finished_id)
        set_match_mat(finished_id, nil)
        changed = true
      end
      changed = fill(mats) || changed
    end
    changed || finished_match.nil?
  end

  def refill
    mat_ids = @tournament.mats.pluck(:id)
    mutate(mat_ids) { |mats| fill(mats) }
  end

  def reset_and_fill
    mat_ids = @tournament.mats.pluck(:id)
    mutate(mat_ids) do |mats|
      Match.where(tournament_id: @tournament.id).where.not(mat_id: nil).update_all(mat_id: nil)
      mats.each { |mat| write_queue(mat, []) }
      fill(mats)
    end
  end

  private

  def mutate(mat_ids)
    return true if mat_ids.empty?

    affected_mats = []
    wrestler_ids = []
    changed_mats = []
    Mat.transaction do
      affected_mats = Mat.where(id: mat_ids).order(:id).lock.to_a
      before_queues = affected_mats.to_h { |mat| [mat.id, mat.queue_match_ids] }
      before_locations = queue_locations(affected_mats)
      yield affected_mats
      affected_mats.each(&:reload)
      changed_mats = affected_mats.select { |mat| before_queues[mat.id] != mat.queue_match_ids }
      after_locations = queue_locations(affected_mats)
      moved_match_ids = (before_locations.keys | after_locations.keys).select do |match_id|
        before_locations[match_id] != after_locations[match_id]
      end
      wrestler_ids = Match.where(id: moved_match_ids).pluck(:w1, :w2).flatten.compact.uniq
    end

    ActiveRecord.after_all_transactions_commit do
      Wrestler.where(id: wrestler_ids).touch_all if wrestler_ids.any?
      changed_mats.each do |mat|
        mat.reload
        mat.broadcast_legacy_mat_view
        mat.broadcast_scoreboard_state
      end
      Tournament.broadcast_up_matches_board(@tournament.id) if changed_mats.any?
    end
    true
  end

  def mats_containing(match_id)
    Mat.where(tournament_id: @tournament.id).where(
      "queue1 = :id OR queue2 = :id OR queue3 = :id OR queue4 = :id", id: match_id
    )
  end

  def queue_locations(mats)
    mats.each_with_object({}) do |mat, locations|
      mat.queue_match_ids.compact.each { |match_id| locations[match_id] = mat.id }
    end
  end

  def collapse(mat, match_id)
    write_queue(mat, mat.queue_match_ids.reject { |id| id == match_id }.compact)
  end

  def write_queue(mat, ids)
    queue = ids.first(4) + [nil] * (4 - ids.first(4).length)
    mat.update_columns(
      queue1: queue[0], queue2: queue[1], queue3: queue[2], queue4: queue[3], updated_at: Time.current
    )
    mat.reload
  end

  def set_match_mat(match_id, mat_id)
    Match.where(id: match_id).update_all(mat_id: mat_id) if match_id
  end

  def fill(mats)
    available = Mat.assignable_matches_for(@tournament.id).to_a
    changed = false
    (1..4).each do |position|
      mats.each do |mat|
        next if mat.public_send("queue#{position}")

        index = available.index { |match| mat.accepts_match?(match) }
        next unless index

        match = available.delete_at(index)
        mat.update_columns("queue#{position}" => match.id, updated_at: Time.current)
        mat.public_send("queue#{position}=", match.id)
        set_match_mat(match.id, mat.id)
        changed = true
      end
    end
    changed
  end
end
