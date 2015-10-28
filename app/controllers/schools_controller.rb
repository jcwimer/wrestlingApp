class SchoolsController < ApplicationController
  before_action :set_school, only: [:show, :edit, :update, :destroy]
  before_filter :check_access, only: [:new,:create,:update,:destroy,:edit]


  # GET /schools/1
  # GET /schools/1.json
  def show
    @wrestlers = @school.wrestlers
    @tournament = @school.tournament
  end

  # GET /schools/new
  def new
    @school = School.new
    if params[:tournament]
      @tournament_field = params[:tournament]
      @tournament = Tournament.find(params[:tournament])
    end
  end

  # GET /schools/1/edit
  def edit
    @tournament_field = @school.tournament_id
    @tournament = Tournament.find(@school.tournament_id)
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
    @school.destroy
    respond_to do |format|
      format.html { redirect_to @tournament }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_school
      @school = School.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def school_params
      params.require(:school).permit(:name, :score, :tournament_id)
    end

    def check_access
	if params[:tournament]
	   @tournament = params[:tournament]
	else
	   @tournament = @school.tournament
	end
	if current_user != @tournament.user
	  redirect_to root_path
	end
    end

end
