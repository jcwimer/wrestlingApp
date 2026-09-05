class SchoolsController < ApplicationController
  before_action :set_school, only: [:show, :edit, :update, :destroy, :stats]
  before_action :check_access_director, only: [:new,:create,:destroy]
  before_action :check_access_delegate, only: [:update,:edit]
  before_action :check_read_access, only: [:show, :stats]

  def stats
    @tournament = @school.tournament
    @school_stats_rows = Rails.cache.fetch(TournamentCacheInvalidator.school_stats_data_key(@school.id)) do
      load_school_wrestlers
      @wrestlers.flat_map do |wrestler|
        @matches_by_wrestler_id[wrestler.id].sort_by(&:bout_number).map do |match|
          {
            wrestler_name: wrestler.name,
            weight: wrestler.weight.max,
            bout_number: match.bout_number,
            bracket_position: match.bracket_position,
            w1_name: match.w1_bracket_name,
            w1_stat: match.w1_stat,
            w2_name: match.w2_bracket_name,
            w2_stat: match.w2_stat,
            result: wrestler.result_by_id(match.id)
          }
        end
      end
    end
  end

  # GET /schools/1
  # GET /schools/1.json
  def show
    session.delete(:return_path)
    @tournament = @school.tournament
  end

  # GET /schools/new
  def new
    @school = School.new
    if params[:tournament]
      @tournament = Tournament.find(params[:tournament])
    end
  end

  # GET /schools/1/edit
  def edit
    @tournament = @school.tournament
  end

  # POST /schools
  # POST /schools.json
  def create
    @school = School.new(school_params)
    @tournament = Tournament.find(school_params[:tournament_id])
    respond_to do |format|
      if @school.save
        format.html { redirect_to @tournament, notice: 'School was successfully created.' }
        format.json { render action: 'show', status: :created, location: @school }
      else
        format.html { render action: 'new' }
        format.json { render json: @school.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /schools/1
  # PATCH/PUT /schools/1.json
  def update
    @tournament = @school.tournament
    respond_to do |format|
      if @school.update(school_params)
        format.html { redirect_to @tournament, notice: 'School was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @school.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /schools/1
  # DELETE /schools/1.json
  def destroy
    @tournament = @school.tournament
    @school.destroy_with_dependents!
    TournamentCacheInvalidator.generation_completed(@tournament.id)
    respond_to do |format|
      format.html { redirect_to @tournament }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_school
      @school = if action_name == "stats"
        School.includes({ tournament: :delegates }, :delegates).find_by(id: params[:id])
      elsif action_name == "show"
        School.includes({ tournament: :delegates }, :delegates, :deductedPoints).find_by(id: params[:id])
      else
        School.includes({ tournament: :delegates }, :delegates, :deductedPoints, wrestlers: [:weight, :deductedPoints, :matches_as_w1, :matches_as_w2]).find_by(id: params[:id])
      end
    end

    def load_school_wrestlers
      match_associations = [:winner, { wrestler1: :school }, { wrestler2: :school }, { weight: :matches }]
      @wrestlers = @school.wrestlers.includes(
        :weight, matches_as_w1: match_associations, matches_as_w2: match_associations
      ).to_a
      @matches_by_wrestler_id = @wrestlers.to_h { |wrestler| [wrestler.id, wrestler.all_matches] }
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def school_params
      params.require(:school).permit(:name, :score, :tournament_id)
    end

    def check_access_director
    	if params[:tournament].present?
    	   @tournament = Tournament.find(params[:tournament])
    	elsif params[:school].present?
    	   @tournament = Tournament.find(params[:school]["tournament_id"])
    	elsif @school
    	   @tournament = @school.tournament
    	end

    	authorize! :manage, @tournament
    end

    def check_access_delegate
      if params[:school].present?
        if school_params[:school_permission_key].present?
          @school_permission_key = params[:school_permission_key]
        end
      end

      if params[:school_permission_key].present?
        @school_permission_key = params[:school_permission_key]
      end

    	authorize! :manage, @school
    end
    
    def check_read_access
      # set @school_permission_key for use in ability
      if params[:school_permission_key].present?
        @school_permission_key = params[:school_permission_key]
      end

      authorize! :read, @school
    end
end
