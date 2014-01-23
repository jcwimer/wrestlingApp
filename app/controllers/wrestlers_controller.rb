class WrestlersController < ApplicationController
  before_action :set_wrestler, only: [:show, :edit, :update, :destroy]

  # GET /wrestlers
  # GET /wrestlers.json
  def index
    @wrestlers = Wrestler.all
    @school = School.find(@wrestler.school_id)
  end

  # GET /wrestlers/1
  # GET /wrestlers/1.json
  def show
    @school = School.find(@wrestler.school_id)
  end

  # GET /wrestlers/new
  def new
    @wrestler = Wrestler.new
    if params[:school]
      @school_field = params[:school]
      @school = School.find(params[:school])
    end
    if @school
      @tournament = Tournament.find(@school.tournament_id)
    end
    if @tournament
      @weight = Weight.where(tournament_id: @tournament.id)
    else
      @weight = Weight.all
    end

  end

  # GET /wrestlers/1/edit
  def edit
    @school_field = @wrestler.school_id
    @school = School.find(@wrestler.school_id)
    @tournament = Tournament.find(@school.tournament_id)
    @weight = Weight.where(tournament_id: @tournament.id)
  end

  # POST /wrestlers
  # POST /wrestlers.json
  def create
    @wrestler = Wrestler.new(wrestler_params)
    @school = School.find(wrestler_params[:school_id])
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
    @school = School.find(@wrestler.school_id)
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

  # DELETE /wrestlers/1
  # DELETE /wrestlers/1.json
  def destroy
    @school = School.find(@wrestler.school_id)
    @wrestler.destroy
    respond_to do |format|
      format.html { redirect_to @school }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_wrestler
      @wrestler = Wrestler.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def wrestler_params
      params.require(:wrestler).permit(:name, :school_id, :weight_id, :seed, :original_seed)
    end
end
