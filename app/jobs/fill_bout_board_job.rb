class FillBoutBoardJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: ->(tournament_id) { "tournament:#{tournament_id}" }, group: "tournament_updates"

  def perform(tournament_id)
    tournament = Tournament.find(tournament_id)
    MatQueueOperation.new(tournament).refresh_bout_board!
  end
end
