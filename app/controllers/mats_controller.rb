class MatsController < ApplicationController
  before_action :set_mat, only: [:show, :state, :scoreboard, :edit, :update, :destroy, :assign_next_match, :select_match]
  before_action :check_access, only: [:new,:create,:update,:destroy,:edit,:show, :state, :scoreboard, :assign_next_match, :select_match]

  # GET /mats/1
  # GET /mats/1.json
  def show
    bout_number_param = params[:bout_number]
    @queue_matches = @mat.queue_matches
    @match = if bout_number_param
      @queue_matches.compact.find { |m| m.bout_number == bout_number_param.to_i }
    else
      @queue_matches[0]
    end
    # If a requested bout is no longer queued, fall back to queue1.
    @match ||= @queue_matches[0]
    @next_match = @queue_matches[1]
    @show_next_bout_button = false
  
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
  
    @match_results_redirect_path = sanitize_mat_redirect_path(params[:redirect_to].presence || request.original_fullpath)
    session[:return_path] = @match_results_redirect_path
    session[:error_return_path] = request.original_fullpath
  end  

  def scoreboard
    @match = @mat.selected_scoreboard_match || @mat.queue1_match
    @tournament = @mat.tournament
  end

  def state
    load_mat_match_context
    @match_state_ruleset = "folkstyle_usa"
  end

  def select_match
    selected_match = @mat.queue_matches.compact.find do |match|
      match.id == params[:match_id].to_i || match.bout_number == params[:bout_number].to_i
    end

    return head :unprocessable_entity unless selected_match || params[:last_match_result].present?

    @mat.set_selected_scoreboard_match!(selected_match) if selected_match
    @mat.set_last_match_result!(params[:last_match_result]) if params.key?(:last_match_result)
    head :no_content
  end

  # GET /mats/new
  def new
    @mat = Mat.new
    if params[:tournament]
      @tournament = Tournament.find(params[:tournament])
    end
  end

  # GET /mats/1/edit
  def edit
    @tournament = Tournament.find(@mat.tournament_id)
  end

  # POST /mats
  # POST /mats.json
  def create
    @mat = Mat.new(mat_params)
    @tournament = Tournament.find(mat_params[:tournament_id])
    respond_to do |format|
      if @mat.save
        format.html { redirect_to @tournament, notice: 'Mat was successfully created.' }
        format.json { render action: 'show', status: :created, location: @mat }
      else
        format.html { render action: 'new' }
        format.json { render json: @mat.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /mats/1/assign_next_match
  def assign_next_match
    @tournament = @mat.tournament_id
    respond_to do |format|
      if @mat.advance_queue!
        format.html { redirect_to "/tournaments/#{@mat.tournament.id}", notice: "Mat #{@mat.name} queue advanced." }
        format.json { head :no_content }
      else
        format.html { redirect_to "/tournaments/#{@mat.tournament.id}", alert: "There was an error." }
        format.json { head :no_content }
      end
    end
  end

  # PATCH/PUT /mats/1
  # PATCH/PUT /mats/1.json
  def update
    @tournament = Tournament.find(@mat.tournament_id)
    respond_to do |format|
      if @mat.update(mat_params)
        format.html { redirect_to @tournament, notice: 'Mat was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @mat.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /mats/1
  # DELETE /mats/1.json
  def destroy
    @tournament = Tournament.find(@mat.tournament_id)
    @mat.destroy
    respond_to do |format|
      format.html { redirect_to @tournament }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_mat
      @mat = Mat.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def mat_params
      params.require(:mat).permit(:name, :tournament_id)
    end

    def check_access
      if params[:tournament]
    	   @tournament = Tournament.find(params[:tournament])
    	elsif params[:mat]
    	   @mat = Mat.new(mat_params)
    	   @tournament = Tournament.find(@mat.tournament_id)
    	elsif @mat
    	   @tournament = @mat.tournament
    	end
    	authorize! :manage, @tournament
    end

    def sanitize_mat_redirect_path(path)
      return nil if path.blank?

      uri = URI.parse(path)
      return nil if uri.scheme.present? || uri.host.present?

      params = Rack::Utils.parse_nested_query(uri.query)
      params.delete("bout_number")
      uri.query = params.to_query.presence
      uri.to_s
    rescue URI::InvalidURIError
      nil
    end

    def load_mat_match_context
      bout_number_param = params[:bout_number]
      @queue_matches = @mat.queue_matches
      @match = if bout_number_param
        @queue_matches.compact.find { |match| match.bout_number == bout_number_param.to_i }
      else
        @queue_matches[0]
      end
      @match ||= @queue_matches[0]
      @next_match = @queue_matches[1]
      @show_next_bout_button = false

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
      else
        @tournament = @mat.tournament
      end

      @match_results_redirect_path = sanitize_mat_redirect_path(params[:redirect_to].presence || request.original_fullpath)
      session[:return_path] = @match_results_redirect_path
      session[:error_return_path] = request.original_fullpath
    end
    
    
end
