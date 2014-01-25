class MatsController < ApplicationController
  before_action :set_mat, only: [:show, :edit, :update, :destroy]

  # GET /mats
  # GET /mats.json
  def index
    @mats = Mat.all
  end

  # GET /mats/1
  # GET /mats/1.json
  def show
  end

  # GET /mats/new
  def new
    @mat = Mat.new
    if params[:tournament]
      @tournament_field = params[:tournament]
      @tournament = Tournament.find(params[:tournament])
    end
  end

  # GET /mats/1/edit
  def edit
    @tournament_field = @mat.tournament_id
  end

  # POST /mats
  # POST /mats.json
  def create
    if user_signed_in?
    else
      redirect_to root_path
    end
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
    if user_signed_in?
    else
      redirect_to root_path
    end
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
    if user_signed_in?
    else
      redirect_to root_path
    end
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
end
