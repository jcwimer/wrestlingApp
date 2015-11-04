class TournamentsController < ApplicationController
  before_action :set_tournament, only: [:show, :edit, :update, :destroy,:up_matches,:no_matches,:team_scores,:weights,:generate_matches]
  before_filter :check_access, only: [:update,:edit,:destroy,:generate_matches]
  before_filter :check_for_matches, only: [:up_matches]
 

  def generate_matches
    @tournament.generateMatchups
  end

  def weights
    @weights = @tournament.weights
    @weights.sort_by{|w| w.max}
  end

  def team_scores
    @schools = @tournament.schools
    @schools.sort_by{|s| s.score}
  end


  def no_matches

  end

 
  def up_matches
    @matches = @tournament.matches.where(mat_id: nil).order('bout_number ASC').limit(10).includes(:wrestlers)
    @mats = @tournament.mats.includes(:matches)
  end

  def index
    @tournaments = Tournament.all.limit(50).includes(:schools,:weights,:mats,:matches,:user,:wrestlers)
  end

  def show
    @schools = @tournament.schools
    @weights = @tournament.weights.sort_by{|x|[x.max]}
    @mats = @tournament.mats
  end

  def new
    @tournament = Tournament.new
  end

  def edit
  end

  def create
    if user_signed_in?
    else
      redirect_to root_path
    end
    @tournament = Tournament.new(tournament_params)
    respond_to do |format|
      if @tournament.save
        format.html { redirect_to @tournament, notice: 'Tournament was successfully created.' }
        format.json { render action: 'show', status: :created, location: @tournament }
      else
        format.html { render action: 'new' }
        format.json { render json: @tournament.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @tournament.update(tournament_params)
        format.html { redirect_to @tournament, notice: 'Tournament was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @tournament.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @tournament.destroy
    respond_to do |format|
      format.html { redirect_to tournaments_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tournament
      @tournament = Tournament.where(:id => params[:id]).includes(:schools,:weights,:mats,:matches,:user,:wrestlers).first
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def tournament_params
      params.require(:tournament).permit(:name, :address, :director, :director_email, :tournament_type, :weigh_in_ref, :user_id)
    end
  
  #Check for tournament owner
  def check_access
    if current_user != @tournament.user
	redirect_to '/static_pages/not_allowed'
    end
  end

  def check_for_matches
    if @tournament
	if @tournament.matches.empty?
	  redirect_to "/tournaments/#{@tournament.id}/no_matches"
	end
    end
  end
end
