class WrestlersController < ApplicationController
  before_action :set_wrestler, only: [:show, :edit, :update, :destroy, :update_pool]
  before_action :check_access, only: [:new, :create, :update, :destroy, :edit, :update_pool]
  before_action :check_read_access, only: [:show]

  # GET /wrestlers/1
  # GET /wrestlers/1.json
  def show
    @school = @wrestler.school
    @tournament = @wrestler.tournament
    @wrestler_points_calc = CalculateWrestlerTeamScore.new(@wrestler)
  end

  # GET /wrestlers/new
  def new
    @wrestler = Wrestler.new
    @school = School.find_by(id: params[:school]) if params[:school]
    # Save the key into an instance variable so the view can use it.
    @school_permission_key = params[:school_permission_key].presence
    @tournament = @school.tournament if @school
    @weights = @tournament.weights.sort_by(&:max) if @tournament
  end

  # GET /wrestlers/1/edit
  def edit
    @tournament = @wrestler.tournament
    @weight = @wrestler.weight
    @school = @wrestler.school
    @weights = @school.tournament.weights.sort_by(&:max)
  end

  # POST /wrestlers
  def create
    @school = School.find_by(id: wrestler_params[:school_id])
    # IMPORTANT: Get the key from wrestler_params (not from params directly)
    @school_permission_key = wrestler_params[:school_permission_key].presence
    @weights = @school.tournament.weights if @school

    # Remove the key from attributes so it isn’t assigned to the model.
    @wrestler = Wrestler.new(wrestler_params.except(:school_permission_key))

    respond_to do |format|
      if @wrestler.save
        redirect_path = session[:return_path] || school_path(@school)
        format.html { redirect_to append_permission_key(redirect_path), notice: 'Wrestler was successfully created.' }
        format.json { render :show, status: :created, location: @wrestler }
      else
        format.html { render :new }
        format.json { render json: @wrestler.errors, status: :unprocessable_entity }
      end
    end
  end  

  # PATCH/PUT /wrestlers/1
  def update
    @tournament = @wrestler.tournament
    @weight = @wrestler.weight
    @school = @wrestler.school
    @weights = @tournament.weights.sort_by(&:max)

    respond_to do |format|
      if @wrestler.update(wrestler_params.except(:school_permission_key))
        redirect_path = session[:return_path] || school_path(@school)
        format.html { redirect_to append_permission_key(redirect_path), notice: 'Wrestler was successfully updated.' }
        format.json { render :show, status: :ok, location: @wrestler }
      else
        format.html { render :edit }
        format.json { render json: @wrestler.errors, status: :unprocessable_entity }
      end
    end
  end  

  # DELETE /wrestlers/1
  def destroy
    @school = @wrestler.school
    @wrestler.destroy
    message = "Wrestler was successfully deleted. This action has removed all matches. Please re-generate matches if you already had matches."

    respond_to do |format|
      redirect_path = session[:return_path] || school_path(@school)
      format.html { redirect_to append_permission_key(redirect_path), notice: message }
      format.json { head :no_content }
    end
  end

  private

  def set_wrestler
    @wrestler = Wrestler.includes(:school, :weight, :tournament, :matches).find_by(id: params[:id])
  end

  def wrestler_params
    params.require(:wrestler).permit(:name, :school_id, :weight_id, :seed, :original_seed, :season_win, 
                                     :season_loss, :criteria, :extra, :offical_weight, :pool, :school_permission_key)
  end  

  def check_access
    if params[:school].present?
       @school = School.find(params[:school])
       #@tournament = Tournament.find(@school.tournament.id)
    elsif params[:wrestler].present?
      if params[:wrestler]["school_id"].present?
           @school = School.find(params[:wrestler]["school_id"])
           if wrestler_params[:school_permission_key].present?
             @school_permission_key = wrestler_params[:school_permission_key]
           end
      else
          @wrestler = Wrestler.find(params[:wrestler]["id"])
          @school = @wrestler.school
      end
    elsif @wrestler
       @school = @wrestler.school
    end

    # set @school_permission_key for use in ability
    if params[:school_permission_key].present?
      @school_permission_key = params[:school_permission_key]
    end
    authorize! :manage, @school
  end  

  def check_read_access
    if params[:school]
      @school = School.find(params[:school])
    elsif params[:wrestler].present?
      if params[:wrestler]["school_id"].present?
            @school = School.find(params[:wrestler]["school_id"])
      else
          @wrestler = Wrestler.find(params[:wrestler]["id"])
          @school = @wrestler.school
      end
      if wrestler_params[:school_permission_key].present?
          @school_permission_key = wrestler_params[:school_permission_key]
      end
   elsif @wrestler
      @school = @wrestler.school
    end

    # set @school_permission_key for use in ability
    if params[:school_permission_key].present?
      @school_permission_key = params[:school_permission_key]
    end
    authorize! :read, @school
  end

  # Helper method to append school_permission_key to redirects if it exists.
  def append_permission_key(path)
    return path unless @school_permission_key.present?

    # If path is an ActiveRecord object, convert to URL.
    path = school_path(path) if path.is_a?(School)
    uri = URI.parse(path)
    query_params = Rack::Utils.parse_nested_query(uri.query || "")
    query_params["school_permission_key"] = @school_permission_key
    uri.query = query_params.to_query
    uri.to_s
  end  
end
