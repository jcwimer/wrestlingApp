class SchoolsController < ApplicationController
  before_action :set_school, only: [:show, :edit, :update, :destroy]
  before_filter :check_access_director, only: [:new,:create,:destroy]
  before_filter :check_access_delegate, only: [:update,:edit]


  # GET /schools/1
  # GET /schools/1.json
  def show
    @wrestlers = @school.wrestlers.includes(:deductedPoints,:matches,:weight)
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
    @school.destroy
    respond_to do |format|
      format.html { redirect_to @tournament }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_school
      @school = School.where(:id => params[:id]).includes(:tournament,:wrestlers,:deductedPoints).first
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def school_params
      params.require(:school).permit(:name, :score, :tournament_id)
    end

    def check_access_director
    	if params[:tournament]
    	   @tournament = Tournament.find(params[:tournament])
    	elsif params[:school]
    	   @tournament = Tournament.find(params[:school]["tournament_id"])
    	elsif @school
    	   @tournament = @school.tournament
    	elsif school_params
    	   @tournament = Tournament.find(school_params[:tournament_id])
    	end
    	authorize! :manage, @tournament
    end
    
    def check_access_delegate
    	authorize! :manage, @school
    end

end
