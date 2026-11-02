# frozen_string_literal: true

require 'test_helper'

class AdvanceWrestlerJobTest < ActiveJob::TestCase
  test 'advancement locks tournament mats and relevant weight matches before loading context' do
    match = matches(:tournament_1_bout_1000)
    match.wrestler1.update_column(:auto_medical_forfeit, true)
    match.update_columns(finished: 1, winner_id: match.w2, win_type: 'Medical Forfeit', score: '', finalized_at: Time.current)
    queries = []
    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
      queries << payload[:sql] if payload[:sql].start_with?('SELECT')
    end

    AdvanceWrestlerJob.perform_now([match.id], match.tournament_id)

    mat_query = queries.index do |sql|
      sql.include?("FROM #{Mat.quoted_table_name}") && sql.include?('ORDER BY')
    end
    match_query = queries.index do |sql|
      sql.include?("FROM #{Match.quoted_table_name}") &&
        sql.include?("WHERE #{Match.quoted_table_name}.\"weight_id\" = #{match.weight_id}") && sql.include?('ORDER BY')
    end
    context_query = queries.index { |sql| sql.include?("FROM #{Weight.quoted_table_name}") }
    assert_not_nil mat_query
    assert_not_nil match_query
    assert_not_nil context_query
    assert_operator mat_query, :<, match_query
    assert_operator match_query, :<, context_query
    assert_equal 'Medical Forfeit', match.reload.win_type
    assert_equal match.w2, match.winner_id
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end

  test 'a manual result completed before advancement locks is preserved' do
    match = matches(:tournament_1_bout_1000)
    match.wrestler1.update_column(:auto_medical_forfeit, true)
    timestamp = Time.current.change(usec: 0)
    completed = false
    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
      next if completed || payload[:sql].exclude?("FROM #{Mat.quoted_table_name}") || payload[:sql].exclude?('ORDER BY')

      completed = true
      Match.where(id: match.id).update_all(finished: 1, winner_id: match.w1, win_type: 'Decision', score: '4-2',
                                           finished_at: timestamp, finalized_at: timestamp)
    end

    AdvanceWrestlerJob.perform_now([match.id], match.tournament_id)

    assert completed
    assert_equal 'Decision', match.reload.win_type
    assert_equal '4-2', match.score
    assert_equal match.w1, match.winner_id
    assert_equal timestamp, match.finished_at
    assert_equal timestamp, match.finalized_at
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end
end
