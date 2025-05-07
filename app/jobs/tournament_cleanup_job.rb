class TournamentCleanupJob < ApplicationJob
  queue_as :default

  def perform
    # Remove or clean up tournaments based on age and match status
    process_old_tournaments
  end

  private

  def process_old_tournaments
    # Get all tournaments older than 1 week that have a user_id
    old_tournaments = Tournament.where('date < ? AND user_id IS NOT NULL', 1.week.ago.to_date)
    
    old_tournaments.each do |tournament|
      # Check if it has any non-BYE finished matches
      has_real_matches = tournament.matches.where(finished: 1).where.not(win_type: 'BYE').exists?
      
      if has_real_matches
        
        # 1. Remove all school delegates
        tournament.schools.each do |school|
          school.delegates.destroy_all
        end
        
        # 2. Remove all tournament delegates
        tournament.delegates.destroy_all
        
        # 3. Set user_id to null
        tournament.update(user_id: nil)
      else
        tournament.destroy
      end
    end
  end
end 