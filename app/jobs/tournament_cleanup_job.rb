class TournamentCleanupJob < ApplicationJob
  queue_as :default

  def perform
    # Remove or clean up tournaments based on age and match status
    process_old_tournaments
  end

  private

  def process_old_tournaments
    # Get all tournaments older than 1 week that have a user_id
    old_tournaments = Tournament.where('date < ? AND user_id IS NOT NULL', 1.week.ago.to_date).includes(
      :matches,
      { schools: :delegates },
      weights: [:wrestlers, :matches]
    )
    
    active_ids, empty_ids = old_tournaments.partition { |tournament|
      tournament.matches.any? { |match| match.finished == 1 && match.win_type != "BYE" }
    }.map { |tournaments| tournaments.map(&:id) }

    cleanup_active_tournaments(active_ids)
    delete_empty_tournaments(empty_ids)
  end

  def cleanup_active_tournaments(tournament_ids)
    return if tournament_ids.empty?

    school_ids = School.where(tournament_id: tournament_ids).select(:id)
    TournamentBackup.where(tournament_id: tournament_ids).delete_all
    SchoolDelegate.where(school_id: school_ids).delete_all
    TournamentDelegate.where(tournament_id: tournament_ids).delete_all
    Tournament.where(id: tournament_ids).update_all(user_id: nil)
  end

  def delete_empty_tournaments(tournament_ids)
    return if tournament_ids.empty?

    weight_ids = Weight.where(tournament_id: tournament_ids).select(:id)
    school_ids = School.where(tournament_id: tournament_ids).select(:id)
    wrestler_ids = Wrestler.where(weight_id: weight_ids).select(:id)

    Match.where(tournament_id: tournament_ids).delete_all
    Teampointadjust.where(wrestler_id: wrestler_ids).or(Teampointadjust.where(school_id: school_ids)).delete_all
    Wrestler.where(id: wrestler_ids).delete_all
    SchoolDelegate.where(school_id: school_ids).delete_all
    MatAssignmentRule.where(tournament_id: tournament_ids).delete_all
    TournamentDelegate.where(tournament_id: tournament_ids).delete_all
    TournamentBackup.where(tournament_id: tournament_ids).delete_all
    TournamentJobStatus.where(tournament_id: tournament_ids).delete_all
    Mat.where(tournament_id: tournament_ids).delete_all
    Weight.where(id: weight_ids).delete_all
    School.where(id: school_ids).delete_all
    Tournament.where(id: tournament_ids).delete_all
  end
end
