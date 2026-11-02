# frozen_string_literal: true

class AutomaticResultsJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: ->(weight) { "tournament:#{weight.tournament_id}" }, group: 'tournament_updates'

  def perform(weight)
    BracketAdvancement::AutomaticResults.new(weight).call
  end
end
