class MatAssignmentRulesController < ApplicationController
  before_action :set_tournament
  before_action :check_access_manage
  before_action :set_mat_assignment_rule, only: [:edit, :update, :destroy]

  def index
    @mat_assignment_rules = @tournament.mat_assignment_rules
    @weights_by_id = @tournament.weights.index_by(&:id) # For quick lookup
  end

  def new
    @mat_assignment_rule = @tournament.mat_assignment_rules.build
    load_form_data
  end

  def create
    @mat_assignment_rule = @tournament.mat_assignment_rules.build(mat_assignment_rule_params)
    load_form_data

    if @mat_assignment_rule.save
      redirect_to tournament_mat_assignment_rules_path(@tournament), notice: 'Mat assignment rule created successfully.'
    else
      render :new
    end
  end

  def edit
    load_form_data
  end

  def update
    load_form_data

    if @mat_assignment_rule.update(mat_assignment_rule_params)
      redirect_to tournament_mat_assignment_rules_path(@tournament), notice: 'Mat assignment rule updated successfully.'
    else
      render :edit
    end
  end

  def destroy
    @mat_assignment_rule.destroy
    redirect_to tournament_mat_assignment_rules_path(@tournament), notice: 'Mat assignment rule was successfully deleted.'
  end

  private

  def set_tournament
    @tournament = Tournament.find(params[:tournament_id])
  end

  def set_mat_assignment_rule
    @mat_assignment_rule = @tournament.mat_assignment_rules.find(params[:id])
  end

  def check_access_manage
    authorize! :manage, @tournament
  end

  def mat_assignment_rule_params
    params[:mat_assignment_rule][:weight_classes] ||= []
    params[:mat_assignment_rule][:bracket_positions] ||= []
    params[:mat_assignment_rule][:rounds] ||= []

    params.require(:mat_assignment_rule).permit(:mat_id, weight_classes: [], bracket_positions: [], rounds: []).tap do |whitelisted|
      whitelisted[:weight_classes] = Array(whitelisted[:weight_classes]).map(&:to_i)
      whitelisted[:rounds] = Array(whitelisted[:rounds]).map(&:to_i)
      whitelisted[:bracket_positions] = Array(whitelisted[:bracket_positions])
    end
  end

  def load_form_data
    @available_mats = @tournament.mats
    @unique_bracket_positions = @tournament.matches.select(:bracket_position).distinct.pluck(:bracket_position)
    @unique_rounds = @tournament.matches.select(:round).distinct.pluck(:round)
  end
end
