class WeightsController < ApplicationController
  before_action :set_weight, only: [:pool_order, :show, :edit, :update, :destroy,:re_gen]
  before_action :check_access_manage, only: [:pool_order, :new,:create,:update,:destroy,:edit, :re_gen]
  before_action :check_access_read, only: [:show]


  # GET /weights/1
  # GET /weights/1.json
  def show
    if params[:wrestler]
      check_access_manage
      respond_to do |format|
        # Sanitize the wrestler parameters
        sanitized_wrestlers = params.require(:wrestler).to_unsafe_h.transform_values do |attributes|
          ActionController::Parameters.new(attributes).permit(:original_seed)
        end
  
        Wrestler.update(sanitized_wrestlers.keys, sanitized_wrestlers.values)
        format.html { redirect_to @weight, notice: 'Seeds were successfully updated.' }
      end
    end
    @wrestlers = @weight.wrestlers
    @tournament = @weight.tournament
    session[:return_path] = "/weights/#{@weight.id}"
  end  

  # GET /weights/new
  def new
    @weight = Weight.new
    if params[:tournament]
      @tournament = Tournament.find(params[:tournament])
    end
  end

  # GET /weights/1/edit
  def edit
    @tournament = Tournament.find(@weight.tournament_id)
    @mats = @tournament.mats
  end

  # POST /weights
  # POST /weights.json
  def create
    @weight = Weight.new(weight_params)
    @tournament = Tournament.find(weight_params[:tournament_id])
      respond_to do |format|
        if @weight.save
          format.html { redirect_to @tournament, notice: 'Weight was successfully created.' }
          format.json { render action: 'show', status: :created, location: @weight }
        else
          format.html { render action: 'new' }
          format.json { render json: @weight.errors, status: :unprocessable_entity }
        end
      end
  end

  # PATCH/PUT /weights/1
  # PATCH/PUT /weights/1.json
  def update
    @tournament = Tournament.find(@weight.tournament_id)
    respond_to do |format|
      if @weight.update(weight_params)
        format.html { redirect_to @tournament, notice: 'Weight was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @weight.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /weights/1
  # DELETE /weights/1.json
  def destroy
    @tournament = Tournament.find(@weight.tournament_id)
    @weight.destroy
    respond_to do |format|
        format.html { redirect_to @tournament }
        format.json { head :no_content }
    end
  end
  
  def re_gen
    @tournament = @weight.tournament
    GenerateTournamentMatches.new(@tournament).generateWeight(@weight)
  end

  def pool_order
    pool = params[:pool_to_order].to_i
    if @weight.all_pool_matches_finished(pool)
      PoolOrder.new(@weight.wrestlers_in_pool(pool)).getPoolOrder
      respond_to do |format|
        format.html { redirect_to @tournament, notice: "Pool #{pool} placing is updating for weight class #{@weight.max}." }
      end
    else
      respond_to do |format|
        format.html { redirect_to @tournament, notice: "Pool #{pool} for weight class #{@weight.max} still has matches to finish." }
      end
    end

  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_weight
      @weight = Weight.where(:id => params[:id]).includes(:tournament,:wrestlers).first
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def weight_params
      params.require(:weight).permit(:max, :tournament_id, :mat_id)
    end
  def check_access_manage
    	if params[:tournament]
    	   @tournament = Tournament.find(params[:tournament])
    	elsif params[:weight]
    	   @tournament = Tournament.find(params[:weight]["tournament_id"])
    	elsif @weight
    	   @tournament = @weight.tournament
    	end
    	authorize! :manage, @tournament
  end

  def check_access_read
    if params[:tournament]
       @tournament = Tournament.find(params[:tournament])
    elsif params[:weight]
       @tournament = Tournament.find(params[:weight]["tournament_id"])
    elsif @weight
       @tournament = @weight.tournament
    end
    authorize! :read, @tournament
end


end
