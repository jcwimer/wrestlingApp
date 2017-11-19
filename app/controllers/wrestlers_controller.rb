class WrestlersController < ApplicationController
  before_action :set_wrestler, only: [:show, :edit, :update, :destroy, :update_pool]
  before_action :check_access, only: [:new,:create,:update,:destroy,:edit,:update_pool]


  

  # GET /wrestlers/1
  # GET /wrestlers/1.json
  def show
    @school = @wrestler.school
    @tournament = @wrestler.tournament
  end

  # GET /wrestlers/new
  def new
    @wrestler = Wrestler.new
    if params[:school]
      @school = School.find(params[:school])
    end
    if @school
      @tournament = Tournament.find(@school.tournament_id)
    end
    if @tournament
      @weights = Weight.where(tournament_id: @tournament.id).sort_by{|w| w.max}
    end

  end

  # GET /wrestlers/1/edit
  def edit
    @weight = @wrestler.weight
    @weights = @school.tournament.weights.sort_by{|w| w.max}
    @school = @wrestler.school
  end

  # POST /wrestlers
  # POST /wrestlers.json
  def create
    @wrestler = Wrestler.new(wrestler_params)
    @school = School.find(wrestler_params[:school_id])
    @weights = @school.tournament.weights
    respond_to do |format|
      if @wrestler.save
        format.html { redirect_to @school, notice: 'Wrestler was successfully created.' }
        format.json { render action: 'show', status: :created, location: @wrestler }
      else
        format.html { render action: 'new' }
        format.json { render json: @wrestler.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /wrestlers/1
  # PATCH/PUT /wrestlers/1.json
  def update
    @tournament = @wrestler.tournament
    @weight = @wrestler.weight
    @weights = @tournament.weights.sort_by{|w| w.max}
    @school = @wrestler.school
    respond_to do |format|
      if @wrestler.update(wrestler_params)
        format.html { redirect_to @school, notice: 'Wrestler was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @wrestler.errors, status: :unprocessable_entity }
      end
    end
  end

  def update_pool
    @tournament = @wrestler.tournament
    @weight = @wrestler.weight
    @weights = @tournament.weights.sort_by{|w| w.max}
    @school = @wrestler.school
    if params[:wrestler]['pool']
      @wrestler.pool = params[:wrestler]['pool']
      respond_to do |format|
        if @wrestler.update(wrestler_params)
          format.html { redirect_to "/weights/#{@wrestler.weight.id}/", notice: 'Wrestler was successfully updated. Please re-generate this weight classes matches.' }
          format.json { head :no_content }
        else
          format.html { render action: 'edit' }
          format.json { render json: @wrestler.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # DELETE /wrestlers/1
  # DELETE /wrestlers/1.json
  def destroy
    @school = @wrestler.school
    @wrestler.destroy
    respond_to do |format|
      format.html { redirect_to @school }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_wrestler
      @wrestler = Wrestler.where(:id => params[:id]).includes(:school, :weight, :tournament, :matches).first
    end
    
    # Never trust parameters from the scary internet, only allow the white list through.
    def wrestler_params
      params.require(:wrestler).permit(:name, :school_id, :weight_id, :seed, :original_seed, :season_win, :season_loss,:criteria,:extra,:offical_weight,:pool)
    end
    def check_access
    	if params[:school]
    	   @school = School.find(params[:school])
    	   #@tournament = Tournament.find(@school.tournament.id)
    	elsif params[:wrestler]
        if params[:wrestler]["school_id"]
             @school = School.find(params[:wrestler]["school_id"])
        else
            @wrestler = Wrestler.find(params[:wrestler]["id"])
            @school = @wrestler.school
        end
    	   #@tournament = Tournament.find(@school.tournament.id)
    	elsif @wrestler
    	   @school = @wrestler.school
    	   #@tournament = @wrestler.tournament
    	elsif wrestler_params
    	   @school = School.find(wrestler_params[:school_id])
    	end
    	authorize! :manage, @school
    end
end
