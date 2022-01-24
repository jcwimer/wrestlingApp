class MatchesController < ApplicationController
  before_action :set_match, only: [:show, :edit, :update, :destroy, :stat]
  before_action :check_access, only: [:edit,:update, :stat]

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
    if params[:match]
      @match = Match.where(:id => params[:match]).includes(:wrestlers).first
    end
    @wrestlers = []
    if @match
      if @match.w1
        @wrestler1_name = @match.wrestler1.name
        @wrestler1_school_name = @match.wrestler1.school.name
        if @match.wrestler1.last_match
          @wrestler1_last_match = time_ago_in_words(@match.wrestler1.last_match.updated_at)
        else
          @wrestler1_last_match = "N/A"
        end
        @wrestlers.push(@match.wrestler1)
      else
        @wrestler1_name = "Not assigned"
        @wrestler1_school_name = "N/A"
        @wrestler1_last_match = "N/A"
      end
      if @match.w2
        @wrestler2_name = @match.wrestler2.name
        @wrestler2_school_name = @match.wrestler2.school.name
        if @match.wrestler2.last_match
          @wrestler2_last_match = time_ago_in_words(@match.wrestler2.last_match.updated_at)
        else
          @wrestler1_last_match = "N/A"
        end
        @wrestlers.push(@match.wrestler2)
      else
        @wrestler2_name = "Not assigned"
        @wrestler2_school_name = "N/A"
        @wrestler2_last_match = "N/A"
      end
      @tournament = @match.tournament
    end
    session[:return_path] = "/tournaments/#{@tournament.id}/matches"
  end


  # PATCH/PUT /matches/1
  # PATCH/PUT /matches/1.json
  def update
    respond_to do |format|
      if @match.update(match_params)
        if session[:return_path]
          format.html { redirect_to session.delete(:return_path), notice: 'Match was successfully updated.' }
        else
          format.html { redirect_to "/tournaments/#{@match.tournament.id}", notice: 'Match was successfully updated.' }
        end
        format.json { head :no_content }
      else
        format.html { redirect_to session.delete(:return_path), alert: "Match did not save because: #{@match.errors.full_messages.to_s}" }
        format.json { render json: @match.errors, status: :unprocessable_entity }
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
      params.require(:match).permit(:w1, :w2, :w1_stat, :w2_stat, :winner_id, :win_type, :score, :finished)
    end

    def check_access
      authorize! :manage, @match.tournament
    end
end
