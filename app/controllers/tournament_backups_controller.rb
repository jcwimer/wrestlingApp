class TournamentBackupsController < ApplicationController
    before_action :set_tournament
    before_action :set_tournament_backup, only: [:show, :destroy, :restore]
    before_action :check_access_manage
  
    # GET /tournament/:tournament_id/tournament_backups
    def index
      @tournament_backups = @tournament.tournament_backups.order(created_at: :desc)
    end
  
    # GET /tournament/:tournament_id/tournament_backups/:id
    def show
    end
  
    # DELETE /tournament/:tournament_id/tournament_backups/:id
    def destroy
      if @tournament_backup.destroy
        redirect_to tournament_tournament_backups_path(@tournament), notice: 'Backup was successfully deleted.'
      else
        redirect_to tournament_tournament_backups_path(@tournament), alert: 'Failed to delete the backup.'
      end
    end
  
    # POST /tournament/:tournament_id/tournament_backups/create
    def create
      TournamentBackupService.new(@tournament, 'Manual backup').create_backup
      redirect_to tournament_tournament_backups_path(@tournament), notice: 'Backup was successfully created. It will show up soon, check your background jobs for status.'
    end
  
    # POST /tournament/:tournament_id/tournament_backups/:id/restore
    def restore
      WrestlingdevImporter.new(@tournament, @tournament_backup).import
      redirect_to tournament_path(@tournament), notice: 'Restore has successfully been submitted, please check your background jobs to see if it has finished.'
    end

    # POST /tournament/:tournament_id/tournament_backups/import_manual
    def import_manual
        import_text = params[:tournament][:import_text]
        if import_text.blank?
        redirect_to tournament_tournament_backups_path(@tournament), alert: 'Import text cannot be blank.'
        return
        end
    
        begin
        
        # Create a temporary backup object
        backup = TournamentBackup.new(
            tournament: @tournament,
            backup_data: Base64.encode64(import_text),
            backup_reason: 'Manual Import'
        )
    
        # Pass the backup object to the importer
        WrestlingdevImporter.new(@tournament, backup).import
    
        redirect_to tournament_path(@tournament), notice: 'Restore has successfully been submitted, please check your background jobs to see if it has finished.'
        rescue JSON::ParserError => e
        redirect_to tournament_tournament_backups_path(@tournament), alert: "Failed to parse JSON: #{e.message}"
        rescue StandardError => e
        redirect_to tournament_tournament_backups_path(@tournament), alert: "An error occurred: #{e.message}"
        end
    end

    private
  
    def set_tournament
      @tournament = Tournament.find(params[:tournament_id])
    end
  
    def set_tournament_backup
      @tournament_backup = @tournament.tournament_backups.find(params[:id])
    end
  
    def check_access_manage
      authorize! :manage, @tournament
    end
  end
  