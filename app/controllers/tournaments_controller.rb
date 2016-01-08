class TournamentsController < ApplicationController
  before_action :set_tournament, only: [:remove_school_delegate,:remove_delegate,:school_delegate,:delegate,:matches,:weigh_in,:weigh_in_weight,:create_custom_weights,:show,:edit,:update,:destroy,:up_matches,:no_matches,:team_scores,:brackets,:generate_matches,:bracket,:all_brackets]
  before_filter :check_access_manage, only: [:remove_school_delegate,:school_delegate,:weigh_in,:weigh_in_weight,:create_custom_weights,:update,:edit,:generate_matches,:matches]
  before_filter :check_access_destroy, only: [:destroy,:delegate,:remove_delegate]

  before_filter :check_for_matches, only: [:up_matches,:bracket,:all_brackets]
  
  def remove_delegate
    if params[:delegate]
      @delegate = TournamentDelegate.find(params[:delegate])
      @delegate.destroy
      respond_to do |format|
        format.html { redirect_to "/tournaments/#{@tournament.id}/delegate", notice: 'Delegated permissions removed successfully' }
      end
    end
  end
  
  def remove_school_delegate
    if params[:delegate]
      @delegate = SchoolDelegate.find(params[:delegate])
      @delegate.destroy
      respond_to do |format|
        format.html { redirect_to "/tournaments/#{@tournament.id}/school_delegate", notice: 'Delegated permissions removed successfully' }
      end
    end
  end
  
  def school_delegate
    if params[:search]
      @users = User.search(params[:search])
    elsif params[:school_delegate]
      @delegate = SchoolDelegate.new
      @delegate.user_id = params[:school_delegate]["user_id"]
      @delegate.school_id = params[:school_delegate]["school_id"]
      respond_to do |format|
        if @delegate.save
          format.html { redirect_to "/tournaments/#{@tournament.id}/school_delegate", notice: 'Delegated permissions added successfully' }
        else
          format.html { redirect_to "/tournaments/#{@tournament.id}/school_delegate", notice: 'There was an issue delegating permissions please try again' }
        end
      end
    else
      @users_delegates = []
      @tournament.schools.each do |s|
        s.delegates.each do |d|
          @users_delegates << d
        end
      end
    end
  end
  
  def delegate
    if params[:search]
      @users = User.search(params[:search])
    elsif params[:tournament_delegate]
      @delegate = TournamentDelegate.new
      @delegate.user_id = params[:tournament_delegate]["user_id"]
      @delegate.tournament_id = @tournament.id
      respond_to do |format|
        if @delegate.save
          format.html { redirect_to "/tournaments/#{@tournament.id}/delegate", notice: 'Delegated permissions added successfully' }
        else
          format.html { redirect_to "/tournaments/#{@tournament.id}/delegate", notice: 'There was an issue delegating permissions please try again' }
        end
      end
    else
      @users_delegates = @tournament.delegates
    end
  end
  
  def matches
    @matches = @tournament.matches.sort_by{|m| m.bout_number}
    if @match
      @w1 = @match.wrestler1
      @w2 = @match.wrestler2
      @wrestlers = [@w1,@w2]
    end
  end
 
  def weigh_in_weight
    if params[:wrestler]
      Wrestler.update(params[:wrestler].keys, params[:wrestler].values)
    end
    if params[:weight]
        @weight = Weight.where(:id => params[:weight]).includes(:wrestlers).first
        @tournament_id = @tournament.id
        @tournament_name = @tournament.name
        @weights = @tournament.weights
    end
    if @weight
      @wrestlers = @weight.wrestlers 
    end
  end

  def weigh_in
      if @tournament
        @weights = @tournament.weights
        @weights = @weights.sort_by{|x|[x.max]}
      end
  end

  def create_custom_weights
    @custom = params[:customValue].to_s
    @tournament.createCustomWeights(@custom)
    redirect_to "/tournaments/#{@tournament.id}"
  end


  def all_brackets
    
  end

  def bracket
      if params[:weight]
        @weight = Weight.where(:id => params[:weight]).includes(:matches,:wrestlers).first
        @matches = @weight.matches
        @wrestlers = @weight.wrestlers.includes(:school)
        @pools = @weight.poolRounds(@matches)
        @bracketType = @weight.pool_bracket_type
      end
  end

  def generate_matches
    @tournament.generateMatchups
  end

  def brackets
    @weights = @tournament.weights.sort_by{|w| w.max}
  end

  def team_scores
    @schools = @tournament.schools
    @schools = @schools.sort_by{|s| s.pageScore}.reverse!
  end


  def no_matches

  end

 
  def up_matches
    @matches = @tournament.matches.where(mat_id: nil).order('bout_number ASC').limit(10).includes(:wrestlers)
    @mats = @tournament.mats.includes(:matches)
  end

  def index
    if params[:search]
      @tournaments = Tournament.search(params[:search]).order("created_at DESC")
    else
      @tournaments = Tournament.all.sort_by{|t| t.daysUntil}.first(20)
    end
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
      params.require(:tournament).permit(:name, :address, :director, :director_email, :tournament_type, :weigh_in_ref, :user_id, :date)
    end
  
  #Check for tournament owner
  def check_access_destroy
    authorize! :destroy, @tournament
  end
  
  def check_access_manage
    authorize! :manage, @tournament
  end

  def check_for_matches
    if @tournament
    	if @tournament.matches.empty? or @tournament.curently_generating_matches == 1
    	  redirect_to "/tournaments/#{@tournament.id}/no_matches"
    	end
    end
  end
end
