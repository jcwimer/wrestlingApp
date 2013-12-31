class WrestlersController < ApplicationController
  before_action :set_wrestler, only: [:show, :edit, :update, :destroy]

  # GET /wrestlers
  # GET /wrestlers.json
  def index
    @wrestlers = Wrestler.all
  end

  # GET /wrestlers/1
  # GET /wrestlers/1.json
  def show
  end

  # GET /wrestlers/new
  def new
    @wrestler = Wrestler.new
  end

  # GET /wrestlers/1/edit
  def edit
  end

  # POST /wrestlers
  # POST /wrestlers.json
  def create
    @wrestler = Wrestler.new(wrestler_params)

    respond_to do |format|
      if @wrestler.save
        format.html { redirect_to @wrestler, notice: 'Wrestler was successfully created.' }
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
    respond_to do |format|
      if @wrestler.update(wrestler_params)
        format.html { redirect_to @wrestler, notice: 'Wrestler was successfully updated.' }
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
    @wrestler.destroy
    respond_to do |format|
      format.html { redirect_to wrestlers_url }
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
