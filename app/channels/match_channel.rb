class MatchChannel < ApplicationCable::Channel
  SCOREBOARD_CACHE_TTL = 1.hours

  def subscribed
    @match = Match.find_by(id: params[:match_id])
    Rails.logger.info "[MatchChannel] Client subscribed with match_id: #{params[:match_id]}. Match found: #{@match.present?}"
    unless @match
      Rails.logger.warn "[MatchChannel] Match not found for ID: #{params[:match_id]}. Subscription may fail."
      reject
      return
    end

    unless can?(:read, @match.tournament)
      reject
      return
    end

    stream_for @match
  end

  def send_scoreboard(data)
    unless @match
      Rails.logger.error "[MatchChannel] Error: send_scoreboard called but @match is nil. Client params on sub: #{params[:match_id]}"
      return
    end

    return unless can_manage_match?

    scoreboard_state = data["scoreboard_state"]
    return if scoreboard_state.blank?

    return if Rails.cache.read(scoreboard_cache_key) == scoreboard_state

    Rails.cache.write(scoreboard_cache_key, scoreboard_state, expires_in: SCOREBOARD_CACHE_TTL)
    MatchChannel.broadcast_to(@match, { scoreboard_state: scoreboard_state })
  end

  def unsubscribed
    Rails.logger.info "[MatchChannel] Client unsubscribed for match #{@match&.id}"
  end

  # Called when client sends data with action: 'send_stat'
  def send_stat(data)
    # Explicit check for @match at the start
    unless @match
      Rails.logger.error "[MatchChannel] Error: send_stat called but @match is nil. Client params on sub: #{params[:match_id]}"
      return # Stop if no match context
    end

    return unless can_manage_match?

    attributes_to_update = {}
    attributes_to_update[:w1_stat] = data['new_w1_stat'] if data.key?('new_w1_stat')
    attributes_to_update[:w2_stat] = data['new_w2_stat'] if data.key?('new_w2_stat')

    return if attributes_to_update.empty?

    changed_attributes = {}
    @match.with_lock do
      @match.reload
      changed_attributes = attributes_to_update.reject do |attribute, value|
        @match.public_send(attribute) == value
      end
      @match.update_columns(changed_attributes) if changed_attributes.any?
    end

    MatchChannel.broadcast_to(@match, changed_attributes) if changed_attributes.any?
  rescue => e
    Rails.logger.error "[MatchChannel] Exception during match stat update for #{@match.id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  # Called when client wants the latest stats immediately after reconnect
  def request_sync
    unless @match
      Rails.logger.error "[MatchChannel] Error: request_sync called but @match is nil. Client params on sub: #{params[:match_id]}"
      return
    end

    payload = {
      w1_stat: @match.w1_stat,
      w2_stat: @match.w2_stat,
      score: @match.score,
      win_type: @match.win_type,
      winner_name: @match.winner&.name,
      winner_id: @match.winner_id,
      finished: @match.finished,
      scoreboard_state: Rails.cache.read(scoreboard_cache_key)
    }.compact

    if payload.present?
      Rails.logger.info "[MatchChannel] request_sync transmit for match #{@match.id} with payload: #{payload.inspect}"
      transmit(payload)
    else
      Rails.logger.info "[MatchChannel] request_sync payload empty for match #{@match.id}, not transmitting."
    end
  end

  private

  def scoreboard_cache_key
    "tournament:#{@match.tournament_id}:match:#{@match.id}:scoreboard_state"
  end

  def can_manage_match?
    can?(:manage, @match.tournament)
  end
end
