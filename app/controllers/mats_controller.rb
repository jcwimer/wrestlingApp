class MatsController < ApplicationController
  before_action :set_mat, only: [:show, :edit, :update, :destroy]
  before_action :check_access, only: [:new,:create,:update,:destroy,:edit,:show]
  before_action :check_for_matches, only: [:show]

  # GET /mats/1
  # GET /mats/1.json
  def show
    @match = @mat.unfinished_matches.first
    if @match
      @w1 = @match.wrestler1
      @w2 = @match.wrestler2
      @wrestlers = [@w1,@w2]
    end
    session[:return_path] = request.original_fullpath
  end

  # GET /mats/new
  def new
    @mat = Mat.new
    if params[:tournament]
      @tournament = Tournament.find(params[:tournament])
    end
  end

  # GET /mats/1/edit
  def edit
    @tournament = Tournament.find(@mat.tournament_id)
  end

  # POST /mats
  # POST /mats.json
  def create
    @mat = Mat.new(mat_params)
    @tournament = Tournament.find(mat_params[:tournament_id])
    respond_to do |format|
      if @mat.save
        format.html { redirect_to @tournament, notice: 'Mat was successfully created.' }
        format.json { render action: 'show', status: :created, location: @mat }
      else
        format.html { render action: 'new' }
        format.json { render json: @mat.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /mats/1
  # PATCH/PUT /mats/1.json
  def update
    @tournament = Tournament.find(@mat.tournament_id)
    respond_to do |format|
      if @mat.update(mat_params)
        format.html { redirect_to @tournament, notice: 'Mat was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @mat.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /mats/1
  # DELETE /mats/1.json
  def destroy
    @tournament = Tournament.find(@mat.tournament_id)
    @mat.destroy
    respond_to do |format|
      format.html { redirect_to @tournament }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_mat
      @mat = Mat.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def mat_params
      params.require(:mat).permit(:name, :tournament_id)
    end

    def check_access
      if params[:tournament]
    	   @tournament = Tournament.find(params[:tournament])
    	elsif params[:mat]
    	   @mat = Mat.new(mat_params)
    	   @tournament = Tournament.find(@mat.tournament_id)
    	elsif @mat
    	   @tournament = @mat.tournament
    	end
    	authorize! :manage, @tournament
    end
    
    
  def check_for_matches
    if @mat
    	if @mat.tournament.matches.empty?
    	  redirect_to "/tournaments/#{@tournament.id}/no_matches"
    	end
    end
  end
end
