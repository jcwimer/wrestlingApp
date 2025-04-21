class MatchChannel < ApplicationCable::Channel
  def subscribed
    @match = Match.find_by(id: params[:match_id])
    Rails.logger.info "[MatchChannel] Client subscribed with match_id: #{params[:match_id]}. Match found: #{@match.present?}"
    if @match
      stream_for @match
    else
      Rails.logger.warn "[MatchChannel] Match not found for ID: #{params[:match_id]}. Subscription may fail."
      # You might want to reject the subscription if the match isn't found
      # reject
    end
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

    Rails.logger.info "[MatchChannel] Received send_stat for match #{@match.id} with data: #{data.inspect}"
    
    # Prepare attributes to update
    attributes_to_update = {}
    attributes_to_update[:w1_stat] = data['new_w1_stat'] if data.key?('new_w1_stat')
    attributes_to_update[:w2_stat] = data['new_w2_stat'] if data.key?('new_w2_stat')

    if attributes_to_update.present?
      # Persist the changes to the database
      # Note: Consider background job or throttling for very high frequency updates
      begin
        if @match.update(attributes_to_update)
          Rails.logger.info "[MatchChannel] Updated match #{@match.id} stats in DB: #{attributes_to_update.keys.join(', ')}"
          
          # Prepare payload for broadcast (using potentially updated values from @match)
          payload = {
            w1_stat: @match.w1_stat,
            w2_stat: @match.w2_stat
          }.compact

          if payload.present?
            Rails.logger.info "[MatchChannel] Broadcasting DB-persisted stats to match #{@match.id} with payload: #{payload.inspect}"
            MatchChannel.broadcast_to(@match, payload)
          else
            Rails.logger.info "[MatchChannel] Payload empty after DB update for match #{@match.id}, not broadcasting."
          end
        else
          Rails.logger.error "[MatchChannel] Failed to update match #{@match.id} stats in DB: #{@match.errors.full_messages.join(', ')}"
        end
      rescue => e
        Rails.logger.error "[MatchChannel] Exception during match update for #{@match.id}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    else
       Rails.logger.info "[MatchChannel] No new stat data provided in send_stat for match #{@match.id}, not updating DB or broadcasting."
    end
  end
end
