class MatchesController < ApplicationController
  before_action :set_match, only: [:show, :edit, :update, :stat, :spectate, :edit_assignment, :update_assignment]
  before_action :check_access, only: [:edit, :update, :stat, :edit_assignment, :update_assignment]

  # GET /matches/1
  # GET /matches/1.json
  def show
    @tournament = @match.tournament
  end


  # GET /matches/1/edit
  def edit
    if params[:match]
      @match = Match.where(:id => params[:match]).includes(:wrestlers).first
    end
    if @match
      @wrestlers = @match.weight.wrestlers
      @tournament = @match.tournament
    end
    session[:return_path] = "/tournaments/#{@match.tournament.id}/matches"
  end

  def stat
    # @show_next_bout_button = false
    if params[:match]
      @match = Match.where(:id => params[:match]).includes(:wrestlers).first
    end
    @wrestlers = []
    if @match
      if @match.w1
        @wrestler1_name = @match.wrestler1.name
        @wrestler1_school_name = @match.wrestler1.school.name
        @wrestler1_last_match = @match.wrestler1.last_match
        @wrestlers.push(@match.wrestler1)
      else
        @wrestler1_name = "Not assigned"
        @wrestler1_school_name = "N/A"
        @wrestler1_last_match = nil
      end
      if @match.w2
        @wrestler2_name = @match.wrestler2.name
        @wrestler2_school_name = @match.wrestler2.school.name
        @wrestler2_last_match = @match.wrestler2.last_match
        @wrestlers.push(@match.wrestler2)
      else
        @wrestler2_name = "Not assigned"
        @wrestler2_school_name = "N/A"
        @wrestler2_last_match = nil
      end
      @tournament = @match.tournament
    end
    if @match&.mat
      @mat = @match.mat
      queue_position = @mat.queue_position_for_match(@match)
      @next_match = queue_position == 1 ? @mat.queue2_match : nil
      @show_next_bout_button = queue_position == 1
      if request.referer&.include?("/tournaments/#{@tournament.id}/matches")
        session[:return_path] = "/tournaments/#{@tournament.id}/matches"
      else
        session[:return_path] = mat_path(@mat)
      end
      session[:error_return_path] = "/matches/#{@match.id}/stat"
    else
      session[:return_path] = "/tournaments/#{@tournament.id}/matches"
      session[:error_return_path] = "/matches/#{@match.id}/stat"
    end
  end

  # GET /matches/:id/spectate
  def spectate
    # Similar to stat, but potentially simplified for read-only view
    # We mainly need @match for the view to get the ID
    # and maybe initial wrestler names/schools
    if @match
      @wrestler1_name = @match.w1 ? @match.wrestler1.name : "Not assigned"
      @wrestler1_school_name = @match.w1 ? @match.wrestler1.school.name : "N/A"
      @wrestler2_name = @match.w2 ? @match.wrestler2.name : "Not assigned"
      @wrestler2_school_name = @match.w2 ? @match.wrestler2.school.name : "N/A"
      @tournament = @match.tournament
    else
      # Handle case where match isn't found, perhaps redirect or render error
      redirect_to root_path, alert: "Match not found."
    end
  end

  # GET /matches/1/edit_assignment
  def edit_assignment
    @tournament = @match.tournament
    @mats = @tournament.mats.sort_by(&:name)
    @current_mat = @match.mat
    @current_queue_position = @current_mat&.queue_position_for_match(@match)
    session[:return_path] = "/tournaments/#{@tournament.id}/matches"
  end

  # PATCH /matches/1/update_assignment
  def update_assignment
    @tournament = @match.tournament
    mat_id = params.dig(:match, :mat_id)
    queue_position = params.dig(:match, :queue_position)

    if mat_id.blank?
      Mat.where("queue1 = :match_id OR queue2 = :match_id OR queue3 = :match_id OR queue4 = :match_id", match_id: @match.id)
         .find_each { |mat| mat.remove_match_from_queue_and_collapse!(@match.id) }
      @match.update(mat_id: nil)
      redirect_to session.delete(:return_path) || "/tournaments/#{@tournament.id}/matches", notice: "Match assignment cleared."
      return
    end

    if queue_position.blank?
      redirect_to edit_assignment_match_path(@match), alert: "Queue position is required when selecting a mat."
      return
    end

    unless %w[1 2 3 4].include?(queue_position.to_s)
      redirect_to edit_assignment_match_path(@match), alert: "Queue position must be between 1 and 4."
      return
    end

    mat = @tournament.mats.find_by(id: mat_id)
    unless mat
      redirect_to edit_assignment_match_path(@match), alert: "Selected mat was not found."
      return
    end

    mat.assign_match_to_queue!(@match, queue_position)
    redirect_to session.delete(:return_path) || "/tournaments/#{@tournament.id}/matches", notice: "Match assignment updated."
  end

  # PATCH/PUT /matches/1
  # PATCH/PUT /matches/1.json
  def update
    respond_to do |format|
      if @match.update(match_params)
        # Broadcast the update
        MatchChannel.broadcast_to(
          @match,
          {
            w1_stat: @match.w1_stat,
            w2_stat: @match.w2_stat,
            score: @match.score,
            win_type: @match.win_type,
            winner_id: @match.winner_id,
            winner_name: @match.winner&.name,
            finished: @match.finished
          }
        )

        if session[:return_path]
          sanitized_return_path = sanitize_return_path(session[:return_path])
          format.html { redirect_to sanitized_return_path, notice: 'Match was successfully updated.' }
          session.delete(:return_path) # Remove the session variable
        else
          format.html { redirect_to "/tournaments/#{@match.tournament.id}", notice: 'Match was successfully updated.' }
        end
        format.json { head :no_content }
      else
        if session[:error_return_path]
          format.html { redirect_to session.delete(:error_return_path), alert: "Match did not save because: #{@match.errors.full_messages.to_s}" }
          format.json { render json: @match.errors, status: :unprocessable_entity }
        else
          format.html { redirect_to "/tournaments/#{@match.tournament.id}", alert: "Match did not save because: #{@match.errors.full_messages.to_s}" }
          format.json { render json: @match.errors, status: :unprocessable_entity }
        end
      end
    end
  end  


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_match
      @match = Match.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def match_params
      params.require(:match).permit(:w1, :w2, :w1_stat, :w2_stat, :winner_id, :win_type, :score, :overtime_type, :finished, :round)
    end

    def check_access
      authorize! :manage, @match.tournament
    end

    def sanitize_return_path(path)
      uri = URI.parse(path)
      params = Rack::Utils.parse_nested_query(uri.query)
      params.delete("bout_number") # Remove the bout_number param
      uri.query = params.to_query.presence # Rebuild the query string or set it to nil if empty
      uri.to_s # Return the full path as a string
    end    
end
