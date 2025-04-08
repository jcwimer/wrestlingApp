require 'test_helper'

class TournamentBackupsControllerTest < ActionController::TestCase
  # Remove Devise helpers since we're no longer using Devise
  # include Devise::Test::ControllerHelpers

  setup do
    @tournament = Tournament.find(1)
    TournamentBackupService.new(@tournament, 'Manual backup').create_backup
    @backup = @tournament.tournament_backups.first
  end

  def sign_in_owner
    sign_in users(:one)
  end

  def sign_in_non_owner
    sign_in users(:two)
  end
  
  def sign_in_delegate
    sign_in users(:three)
  end
  
  def sign_in_school_delegate
    sign_in users(:four)
  end

  def success
    assert_response :success
  end

  def redirect
    assert_redirected_to '/static_pages/not_allowed'
  end

  # Index endpoint tests
  test "logged in tournament owner can access index" do
    sign_in_owner
    get :index, params: { tournament_id: @tournament.id }
    assert_response :success
  end

  test "logged in delegate can access index" do
    sign_in_delegate
    get :index, params: { tournament_id: @tournament.id }
    assert_response :success
  end

  test "non-tournament owner cannot access index" do
    sign_in_non_owner
    get :index, params: { tournament_id: @tournament.id }
    redirect
  end

  test "school delegate cannot access index" do
    sign_in_school_delegate
    get :index, params: { tournament_id: @tournament.id }
    redirect
  end

  # Show endpoint tests
  test "tournament owner can view a backup" do
    sign_in_owner
    get :show, params: { tournament_id: @tournament.id, id: @backup.id }
    assert_response :success
  end

  test "delegate can view a backup" do
    sign_in_delegate
    get :show, params: { tournament_id: @tournament.id, id: @backup.id }
    assert_response :success
  end

  test "non-tournament owner cannot view a backup" do
    sign_in_non_owner
    get :show, params: { tournament_id: @tournament.id, id: @backup.id }
    redirect
  end

  test "school delegate cannot view a backup" do
    sign_in_school_delegate
    get :show, params: { tournament_id: @tournament.id, id: @backup.id }
    redirect
  end

  # Destroy endpoint tests
  test "tournament owner can delete a backup" do
    sign_in_owner
    assert_difference("TournamentBackup.count", -1) do
      delete :destroy, params: { tournament_id: @tournament.id, id: @backup.id }
    end
    assert_redirected_to tournament_tournament_backups_path(@tournament)
  end

  test "delegate can delete a backup" do
    sign_in_delegate
    assert_difference("TournamentBackup.count", -1) do
      delete :destroy, params: { tournament_id: @tournament.id, id: @backup.id }
    end
    assert_redirected_to tournament_tournament_backups_path(@tournament)
  end

  test "non-tournament owner cannot delete a backup" do
    sign_in_non_owner
    assert_no_difference("TournamentBackup.count") do
      delete :destroy, params: { tournament_id: @tournament.id, id: @backup.id }
    end
    redirect
  end

  test "school delegate cannot delete a backup" do
    sign_in_school_delegate
    assert_no_difference("TournamentBackup.count") do
      delete :destroy, params: { tournament_id: @tournament.id, id: @backup.id }
    end
    redirect
  end

  # Restore endpoint tests
  test "tournament owner can restore a backup" do
    sign_in_owner
    post :restore, params: { tournament_id: @tournament.id, id: @backup.id }
    assert_redirected_to tournament_path(@tournament)
  end

  test "delegate can restore a backup" do
    sign_in_delegate
    post :restore, params: { tournament_id: @tournament.id, id: @backup.id }
    assert_redirected_to tournament_path(@tournament)
  end

  test "non-tournament owner cannot restore a backup" do
    sign_in_non_owner
    post :restore, params: { tournament_id: @tournament.id, id: @backup.id }
    redirect
  end

  test "school delegate cannot restore a backup" do
    sign_in_school_delegate
    post :restore, params: { tournament_id: @tournament.id, id: @backup.id }
    redirect
  end

  # Import manual tests
  test "tournament owner can manually import a backup" do
    sign_in_owner
    post :import_manual, params: { tournament_id: @tournament.id, tournament: { import_text: Base64.decode64(@backup.backup_data) } }
    assert_redirected_to tournament_path(@tournament)
  end

  test "delegate can manually import a backup" do
    sign_in_delegate
    post :import_manual, params: { tournament_id: @tournament.id, tournament: { import_text: Base64.decode64(@backup.backup_data) } }
    assert_redirected_to tournament_path(@tournament)
  end

  test "non-tournament owner cannot manually import a backup" do
    sign_in_non_owner
    post :import_manual, params: { tournament_id: @tournament.id, tournament: { import_text: Base64.decode64(@backup.backup_data) } }
    redirect
  end

  test "school delegate cannot manually import a backup" do
    sign_in_school_delegate
    post :import_manual, params: { tournament_id: @tournament.id, tournament: { import_text: Base64.decode64(@backup.backup_data) } }
    redirect
  end

  test "index shows empty list when no backups exist" do
    @tournament.tournament_backups.destroy_all
    sign_in_owner
    get :index, params: { tournament_id: @tournament.id }
    assert_response :success
    assert_select 'tbody tr', 0 # Ensure no rows are rendered in the table
  end

  test "show action for non-existent backup" do
    sign_in_owner
    assert_raises(ActiveRecord::RecordNotFound) do
      get :show, params: { tournament_id: @tournament.id, id: 9999 } # Use a non-existent backup ID
    end
  end
  
  test "destroy action for non-existent backup" do
    sign_in_owner
    assert_no_difference("TournamentBackup.count") do
      assert_raises(ActiveRecord::RecordNotFound) do
        delete :destroy, params: { tournament_id: @tournament.id, id: 9999 } # Use a non-existent backup ID
      end
    end
  end

  test "restore action for non-existent backup" do
    sign_in_owner
    assert_raises(ActiveRecord::RecordNotFound) do
      post :restore, params: { tournament_id: @tournament.id, id: 9999 } # Use a non-existent backup ID
    end
  end

  test "manual import with blank input" do
    sign_in_owner
    post :import_manual, params: { tournament_id: @tournament.id, tournament: { import_text: '' } }
    assert_redirected_to tournament_tournament_backups_path(@tournament)
    assert_equal 'Import text cannot be blank.', flash[:alert]
  end

  test "manual import restores associations" do
    schools_count = @tournament.schools.count
    wrestlers_count = @tournament.wrestlers.count
    matches_count = @tournament.matches.count
    sign_in_owner
    valid_backup_data = Base64.decode64(@backup.backup_data)
    post :import_manual, params: { tournament_id: @tournament.id, tournament: { import_text: valid_backup_data } }
  
    @tournament.reload
    assert_equal schools_count, @tournament.schools.count
    assert_equal wrestlers_count, @tournament.wrestlers.count
    assert_equal matches_count, @tournament.matches.count
  end  
end
