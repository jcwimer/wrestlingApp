# frozen_string_literal: true

require 'test_helper'

class TournamentUpdatesBackupImportTest < ActionDispatch::IntegrationTest
  test 'backup and import preserves wrestler medical forfeits, tournament posts, and school emails' do
    source = tournaments(:one)
    target = tournaments(:two)
    school = source.schools.first
    source_wrestler = school.wrestlers.first
    source_wrestler.update!(auto_medical_forfeit: true)
    school.update!(email: ' Coach@Example.com ')
    timestamp = Time.zone.parse('2025-03-04 10:30:00.123')
    public_post = source.tournament_posts.create!(title: 'Schedule change', body: 'Weigh-ins start at 8:00.',
                                                  is_public: true, created_at: timestamp, updated_at: timestamp)
    source.tournament_posts.create!(title: 'Coach note', body: 'Bring credentials.', is_public: false)

    TournamentServices::TournamentBackupService.new(source, 'Manual').create_backup_raw
    backup_record = source.tournament_backups.last
    backup_data = JSON.parse(Base64.decode64(backup_record.backup_data))
    assert_equal 'coach@example.com', backup_data.dig('tournament', 'schools', 0, 'email')
    backed_up_wrestler = backup_data.dig('tournament', 'wrestlers').find do |wrestler|
      wrestler['name'] == source_wrestler.name
    end
    assert_equal true, backed_up_wrestler['auto_medical_forfeit']
    backup_posts = backup_data.dig('tournament', 'tournament_posts').index_by { |post| post['title'] }
    assert_equal true, backup_posts.dig('Schedule change', 'is_public')
    assert_equal false, backup_posts.dig('Coach note', 'is_public')

    target.tournament_posts.create!(title: 'Old update', body: 'This should be replaced.')
    TournamentServices::WrestlingdevImporter.new(target, backup_record).import_raw

    imported_posts = target.tournament_posts.index_by(&:title)
    imported_public_post = imported_posts.fetch('Schedule change')
    imported_private_post = imported_posts.fetch('Coach note')
    assert_equal 'Weigh-ins start at 8:00.', imported_public_post.body
    assert_equal public_post.created_at, imported_public_post.created_at
    assert_equal public_post.updated_at, imported_public_post.updated_at
    assert_predicate imported_public_post, :is_public?
    assert_not_predicate imported_private_post, :is_public?
    assert_equal 'coach@example.com', target.schools.find_by!(name: school.name).email
    imported_wrestler = target.schools.find_by!(name: school.name).wrestlers.find_by!(name: source_wrestler.name)
    assert_predicate imported_wrestler, :auto_medical_forfeit?
  end

  test 'imports legacy medical default wrestler and match data as medical forfeits' do
    source = tournaments(:one)
    target = tournaments(:two)
    source_wrestler = source.schools.first.wrestlers.first
    source_wrestler.update!(auto_medical_forfeit: true)
    TournamentServices::TournamentBackupService.new(source, 'Manual').create_backup_raw
    backup_record = source.tournament_backups.last
    backup_data = JSON.parse(Base64.decode64(backup_record.backup_data))

    backed_up_wrestler = backup_data.dig('tournament', 'wrestlers').find do |wrestler|
      wrestler['name'] == source_wrestler.name
    end
    backed_up_wrestler['auto_medical_default'] = backed_up_wrestler.delete('auto_medical_forfeit')
    backed_up_match = backup_data.dig('tournament', 'matches').first
    backed_up_match['win_type'] = 'Medical Default'
    backup_record.update!(backup_data: Base64.encode64(backup_data.to_json))

    TournamentServices::WrestlingdevImporter.new(target, backup_record).import_raw

    imported_school = target.reload.schools.find_by!(name: source_wrestler.school.name)
    imported_wrestler = imported_school.wrestlers.find_by!(name: source_wrestler.name)
    imported_match = target.matches.find_by!(bout_number: backed_up_match['bout_number'])
    assert_predicate imported_wrestler, :auto_medical_forfeit?
    assert_equal 'Medical Forfeit', imported_match.win_type
  end

  test 'legacy backup without wrestler medical forfeit, tournament posts, or school email imports safely' do
    source = tournaments(:one)
    target = tournaments(:two)
    source.schools.first.update!(email: 'coach@example.com')
    TournamentServices::TournamentBackupService.new(source, 'Manual').create_backup_raw
    backup_record = source.tournament_backups.last
    backup_data = JSON.parse(Base64.decode64(source.tournament_backups.last.backup_data))
    backup_data['tournament'].delete('tournament_posts')
    backup_data['tournament']['schools'].each { |school| school.delete('email') }
    backup_data['tournament']['wrestlers'].each { |wrestler| wrestler.delete('auto_medical_forfeit') }
    backup_record.update!(backup_data: Base64.encode64(backup_data.to_json))

    target.tournament_posts.create!(title: 'Old update', body: 'Remove during import.')
    assert_no_enqueued_jobs do
      TournamentServices::WrestlingdevImporter.new(target, backup_record).import_raw
    end

    assert_empty target.tournament_posts
    assert_not_predicate target.reload.weights.first.wrestlers.first, :auto_medical_forfeit?
  end

  test 'legacy post backup without is_public restores missing flags as private' do
    source = tournaments(:one)
    target = tournaments(:two)
    source_post = source.tournament_posts.create!(title: 'Private update', body: 'Director only details.', is_public: false)
    source.tournament_posts.create!(title: 'Public update', body: 'Doors open at 8.', is_public: true)
    TournamentServices::TournamentBackupService.new(source, 'Manual').create_backup_raw
    backup_record = source.tournament_backups.last
    backup_data = JSON.parse(Base64.decode64(backup_record.backup_data))
    backed_up_posts = backup_data.dig('tournament', 'tournament_posts')
    backed_up_posts.find { |post| post['title'] == source_post.title }.delete('is_public')
    backup_record.update!(backup_data: Base64.encode64(backup_data.to_json))

    assert_no_enqueued_jobs do
      TournamentServices::WrestlingdevImporter.new(target, backup_record).import_raw
    end

    imported_posts = target.tournament_posts.index_by(&:title)
    assert_not_predicate imported_posts.fetch('Private update'), :is_public?
    assert_predicate imported_posts.fetch('Public update'), :is_public?
  end

  test 'custom tournament deletion removes tournament posts' do
    tournament = Tournament.create!(name: 'Posts Tournament', address: 'Gym', director: 'Coach',
                                    director_email: 'coach@example.com', tournament_type: 'Pool to bracket',
                                    date: '2025-01-01')
    tournament.tournament_posts.create!(title: 'Update one', body: 'First update.')
    tournament.tournament_posts.create!(title: 'Update two', body: 'Second update.')

    assert_difference('TournamentPost.count', -2) do
      tournament.destroy_with_dependents!
    end
    assert_not Tournament.exists?(tournament.id)
  end
end
