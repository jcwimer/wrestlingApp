class WrestlersController < ApplicationController
  before_action :set_wrestler, only: [:show, :edit, :update, :destroy, :update_pool]
  before_action :check_access, only: [:new, :create, :update, :destroy, :edit, :update_pool]

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
    @school_permission_key = params[:school_permission_key].presence
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
    @school_permission_key = wrestler_params[:school_permission_key].presence

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
    @school_permission_key = params[:school_permission_key].presence
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
    if params[:school]
      @school = School.find_by(id: params[:school])
    elsif params[:wrestler]
      @school = School.find_by(id: params[:wrestler]["school_id"]) if params[:wrestler]["school_id"]
      @wrestler = Wrestler.find_by(id: params[:wrestler]["id"]) unless @school
      @school ||= @wrestler&.school
    elsif @wrestler
      @school = @wrestler.school
    elsif request.post? || request.patch? || request.put?
      @school = School.find_by(id: wrestler_params[:school_id]) if wrestler_params[:school_id].present?
    end
  
    # Use the permitted key if available.
    @school_permission_key = (params[:school_permission_key] || wrestler_params[:school_permission_key]).presence
  
    # Authorization check
    if @school_permission_key.present? && @school&.permission_key == @school_permission_key
      Rails.logger.info "Authorization GRANTED via school_permission_key"
      return
    end
  
    authorize! :manage, @school
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
