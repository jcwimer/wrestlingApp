class MatchesController < ApplicationController
  before_action :set_match, only: [:show, :edit, :update, :destroy]
  before_action :check_access, only: [:edit,:update]

  # GET /matches/1
  # GET /matches/1.json
  def show
  end


  # GET /matches/1/edit
  def edit
    if params[:match]
      @match = Match.find (params[:match])
    end
    if @match
      @w1 = Wrestler.find(@match.w1)
      @w2 = Wrestler.find(@match.w2)
    end
  end


  # PATCH/PUT /matches/1
  # PATCH/PUT /matches/1.json
  def update
    respond_to do |format|
      if @match.update(match_params)
        format.html { redirect_to root_path, notice: 'Match was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
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
      params.require(:match).permit(:w1, :w2, :g_stat, :r_stat, :winner_id, :win_type, :score, :finished)
    end

    def check_access
	if current_user != @match.tournament.user
	  redirect_to root_path
        end
    end
end
