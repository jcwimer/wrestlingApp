class SchoolsController < ApplicationController
  before_action :set_school, only: [:import_baumspage_roster, :show, :edit, :update, :destroy, :stats]
  before_action :check_access_director, only: [:new,:create,:destroy]
  before_action :check_access_delegate, only: [:import_baumspage_roster, :update,:edit]
  before_action :check_read_access, only: [:show, :stats]

  def stats
    @tournament = @school.tournament
  end

  # GET /schools/1
  # GET /schools/1.json
  def show
    session.delete(:return_path)
    @wrestlers = @school.wrestlers.includes(:deductedPoints,:matches,:weight,:school)
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

  def import_baumspage_roster
    import_text = params[:school][:baums_text]
    respond_to do |format|
      if BaumspageRosterImport.new(@school,import_text).import_roster
        format.html { redirect_to "/schools/#{@school.id}", notice: 'Import successful' }
        format.json { render action: 'show', status: :created, location: @school }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_school
      @school = School.where(:id => params[:id]).includes(:tournament,:wrestlers,:deductedPoints,:delegates).first
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def school_params
      params.require(:school).permit(:name, :score, :tournament_id, :baums_text)
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
