class TournamentsController < ApplicationController
  before_action :set_tournament, only: [:all_results, :delete_school_keys, :generate_school_keys,:reset_bout_board,:calculate_team_scores,:bout_sheets,:swap,:weigh_in_sheet,:error,:teampointadjust,:remove_teampointadjust,:remove_school_delegate,:remove_delegate,:school_delegate,:delegate,:matches,:weigh_in,:weigh_in_weight,:create_custom_weights,:show,:edit,:update,:destroy,:up_matches,:no_matches,:team_scores,:generate_matches,:bracket,:all_brackets,:qrcode,:live_scores]
  before_action :check_access_manage, only: [:delete_school_keys, :generate_school_keys,:reset_bout_board,:calculate_team_scores,:swap,:weigh_in_sheet,:teampointadjust,:remove_teampointadjust,:remove_school_delegate,:school_delegate,:weigh_in,:weigh_in_weight,:create_custom_weights,:update,:edit,:generate_matches,:matches,:qrcode]
  before_action :check_access_destroy, only: [:destroy,:delegate,:remove_delegate]
  before_action :check_tournament_errors, only: [:generate_matches]
  before_action :check_for_matches, only: [:all_results,:bracket,:all_brackets]
  before_action :check_access_read, only: [:all_results,:up_matches,:bracket,:all_brackets,:live_scores]

  def weigh_in_sheet
    @schools = @tournament.schools.includes(wrestlers: :weight)
  end

  def calculate_team_scores
    respond_to do |format|
      if @tournament.calculate_all_team_scores
        format.html { redirect_to "/tournaments/#{@tournament.id}", notice: 'Team scores are calcuating.' }
        format.json { head :no_content }
      end
    end
  end

  def swap
    @wrestler = Wrestler.find(params[:wrestler][:originalId])
    respond_to do |format|
      if SwapWrestlers.new.swap_wrestlers_bracket_lines(params[:wrestler][:originalId], params[:wrestler][:swapId])
        format.html { redirect_to "/tournaments/#{@wrestler.tournament.id}/brackets/#{@wrestler.weight.id}", notice: 'Wrestlers successfully swapped.' }
        format.json { render action: 'show', status: :created, location: @wrestler }
      end
    end
  end

  def remove_teampointadjust
    if params[:teampointadjust]
      @points = Teampointadjust.find(params[:teampointadjust])
      @points.destroy
      respond_to do |format|
        format.html { redirect_to "/tournaments/#{@tournament.id}/teampointadjust", notice: 'Point adjustment removed successfully' }
      end
    end
  end

  def teampointadjust
    if params[:teampointadjust]
      @points = Teampointadjust.new
      @points.wrestler_id = params[:teampointadjust]["wrestler_id"]
      @points.school_id = params[:teampointadjust]["school_id"]
      @points.points = params[:teampointadjust]["points"]
      respond_to do |format|
        if @points.save
          format.html { redirect_to "/tournaments/#{@tournament.id}/teampointadjust", notice: 'Point adjustment added successfully' }
        else
          format.html { redirect_to "/tournaments/#{@tournament.id}/teampointadjust", notice: 'There was an issue saving point adjustment please try again' }
        end
      end
    else
      @point_adjustments = @tournament.pointAdjustments
    end
  end

  def remove_delegate
    if params[:delegate]
      @delegate = TournamentDelegate.find(params[:delegate])
      @delegate.destroy
      respond_to do |format|
        format.html { redirect_to "/tournaments/#{@tournament.id}/delegate", notice: 'Delegated permissions removed successfully' }
      end
    end
  end

  def remove_school_delegate
    if params[:delegate]
      @delegate = SchoolDelegate.find(params[:delegate])
      @delegate.destroy
      respond_to do |format|
        format.html { redirect_to "/tournaments/#{@tournament.id}/school_delegate", notice: 'Delegated permissions removed successfully' }
      end
    end
  end

  def school_delegate
    if params[:search]
      @user = User.where('email = ?', params[:search]).first
    elsif params[:school_delegate]
      @delegate = SchoolDelegate.new
      @delegate.user_id = params[:school_delegate]["user_id"]
      @delegate.school_id = params[:school_delegate]["school_id"]
      respond_to do |format|
        if @delegate.save
          format.html { redirect_to "/tournaments/#{@tournament.id}/school_delegate", notice: 'Delegated permissions added successfully' }
        else
          format.html { redirect_to "/tournaments/#{@tournament.id}/school_delegate", notice: 'There was an issue delegating permissions please try again' }
        end
      end
    end
    @users_delegates = SchoolDelegate.includes(:user, :school)
                                     .joins(:school)
                                     .where(schools: { tournament_id: @tournament.id })
  end

  def delegate
    if params[:search]
      @user = User.where('email = ?', params[:search]).first
    elsif params[:tournament_delegate]
      @delegate = TournamentDelegate.new
      @delegate.user_id = params[:tournament_delegate]["user_id"]
      @delegate.tournament_id = @tournament.id
      respond_to do |format|
        if @delegate.save
          format.html { redirect_to "/tournaments/#{@tournament.id}/delegate", notice: 'Delegated permissions added successfully' }
        else
          format.html { redirect_to "/tournaments/#{@tournament.id}/delegate", notice: 'There was an issue delegating permissions please try again' }
        end
      end
    end
    @users_delegates = @tournament.delegates.includes(:user)
  end

  def matches
    per_page = 50
    @page = params[:page].to_i > 0 ? params[:page].to_i : 1
    offset = (@page - 1) * per_page
    matches_table = Match.arel_table

    matches_scope = @tournament.matches.order(:bout_number)

    if params[:search].present?
      wrestlers_table = Wrestler.arel_table
      schools_table = School.arel_table
      search_terms = params[:search].downcase.split

      search_terms.each do |term|
        escaped_term = ActiveRecord::Base.sanitize_sql_like(term)
        pattern = "%#{escaped_term}%"

        matching_wrestler_ids = Wrestler
          .joins(:weight)
          .left_outer_joins(:school)
          .where(weights: { tournament_id: @tournament.id })
          .where(
            wrestlers_table[:name].matches(pattern)
              .or(schools_table[:name].matches(pattern))
          )
          .distinct
          .select(:id)

        term_scope = @tournament.matches.where(w1: matching_wrestler_ids)
          .or(@tournament.matches.where(w2: matching_wrestler_ids))

        if term.match?(/\A\d+\z/)
          term_scope = term_scope.or(@tournament.matches.where(bout_number: term.to_i))
        end

        matches_scope = matches_scope.where(id: term_scope.select(:id))
      end
    end

    @total_count = matches_scope.count
    @total_pages = (@total_count / per_page.to_f).ceil
    @per_page = per_page

    loser1_not_bye = matches_table[:loser1_name].not_eq("BYE").or(matches_table[:loser1_name].eq(nil))
    loser2_not_bye = matches_table[:loser2_name].not_eq("BYE").or(matches_table[:loser2_name].eq(nil))

    non_bye_scope = matches_scope.where(loser1_not_bye).where(loser2_not_bye)
    @matches_without_byes_count = non_bye_scope.count
    @unfinished_matches_without_byes_count = non_bye_scope.where(finished: [nil, 0]).count

    @matches = matches_scope
      .includes({ wrestler1: :school }, { wrestler2: :school }, { weight: :matches })
      .offset(offset)
      .limit(per_page)
    if @match
      @w1 = @match.wrestler1
      @w2 = @match.wrestler2
      @wrestlers = [@w1,@w2]
    end
  end

  def weigh_in_weight
    if params[:wrestler]
      sanitized_wrestlers = params.require(:wrestler).to_unsafe_h.each_with_object({}) do |(wrestler_id, attributes), result|
        permitted = ActionController::Parameters.new(attributes).permit(:offical_weight)
        result[wrestler_id] = permitted
      end
      Wrestler.update(sanitized_wrestlers.keys, sanitized_wrestlers.values) if sanitized_wrestlers.present?
      redirect_to "/tournaments/#{@tournament.id}/weigh_in/#{params[:weight]}", notice: "Weights were successfully recorded."
      return
    end
    if params[:weight]
        @weight = Weight.where(id: params[:weight])
                        .includes(wrestlers: [:school, :weight])
                        .first
        @tournament_id = @tournament.id
        @tournament_name = @tournament.name
        @weights = @tournament.weights
    end
    if @weight
      @wrestlers = @weight.wrestlers
    end
  end

  def weigh_in
      if @tournament
        @weights = @tournament.weights
        @weights = @weights.sort_by{|x|[x.max]}
      end
  end

  def create_custom_weights
    @custom = params[:customValue].split(",")
    @tournament.create_pre_defined_weights(@custom)
    redirect_to "/tournaments/#{@tournament.id}"
  end


  def all_brackets
    @team_scores = cached_team_scores
    @weights = @tournament.weights.includes(:matches, wrestlers: :school)
    all_matches = @tournament.matches.includes(:weight, { wrestler1: :school }, { wrestler2: :school })
    all_wrestlers = @tournament.wrestlers.includes(:school, :weight, :matches_as_w1, :matches_as_w2)
    @matches_by_weight_id = all_matches.group_by(&:weight_id)
    @wrestlers_by_weight_id = all_wrestlers.group_by(&:weight_id)
    @matches_by_weight_id.each_value do |matches|
      first_round = matches.map(&:round).compact.min
      matches.each { |match| match.instance_variable_set(:@first_round_for_weight, first_round) }
    end
  end

  def bracket
    if params[:weight]
      @weight = Weight.includes(
        { matches: [{ wrestler1: :school }, { wrestler2: :school }] },
        wrestlers: [:school, :matches_as_w1, :matches_as_w2]
      ).find_by(id: params[:weight])
      @matches = @weight.matches
      @wrestlers = @weight.wrestlers
      
      if @tournament.tournament_type == "Pool to bracket"
        @pools = @weight.pool_rounds(@matches)
        @bracketType = @weight.pool_bracket_type
      end
    end
  end

  def all_results
    @matches = @tournament.matches.includes(:schools,:wrestlers,:weight)
    @round = nil
    @bracket_position = nil
  end

  def live_scores
    @mats = Mat.where(tournament_id: @tournament.id).order(:name).to_a
    keys = @mats.flat_map { |mat| [mat.scoreboard_selection_cache_key, mat.last_match_result_cache_key] }
    cached = Rails.cache.read_multi(*keys)
    selected_ids = @mats.filter_map do |mat|
      selection = cached[mat.scoreboard_selection_cache_key]
      match_id = selection && (selection[:match_id] || selection["match_id"])
      match_id if mat.queue_match_ids.include?(match_id)
    end
    match_ids = (@mats.flat_map(&:queue_match_ids).compact | selected_ids)
    matches_by_id = Match.where(id: match_ids)
      .includes(:weight, { wrestler1: :school }, { wrestler2: :school })
      .index_by(&:id)

    @live_score_matches = {}
    @live_score_results = {}
    @mats.each do |mat|
      selection = cached[mat.scoreboard_selection_cache_key]
      selected_id = selection && (selection[:match_id] || selection["match_id"])
      @live_score_matches[mat.id] = matches_by_id[selected_id] || matches_by_id[mat.queue1]
      @live_score_results[mat.id] = cached[mat.last_match_result_cache_key]
    end
  end

  def generate_matches
    GenerateTournamentMatches.new(@tournament).generate
  end

  def team_scores
    @team_scores = cached_team_scores
  end


  def no_matches

  end

  def qrcode
    @tournament_url = tournament_url(@tournament)
    @qrcode = RQRCode::QRCode.new(@tournament_url)
  end


  def up_matches
    @matches = @tournament.up_matches_unassigned_matches
    @mats = @tournament.up_matches_mats
  end

  def bout_sheets
    matches_scope = @tournament.matches
                             .where("loser1_name != ? OR loser1_name IS NULL", "BYE")
                             .where("loser2_name != ? OR loser2_name IS NULL", "BYE")

    if params[:round]
      round = params[:round]
      if round != "All"
        @matches = matches_scope
                              .where(round: round)
                              .includes(:weight)
                              .order(:bout_number)
      else
        @matches = matches_scope
                              .includes(:weight)
                              .order(:bout_number)
      end

      wrestler_ids = @matches.flat_map { |match| [match.w1, match.w2] }.compact.uniq
      @wrestlers_by_id = Wrestler.includes(:school).where(id: wrestler_ids).index_by(&:id)
    end
  end

  def index
    per_page = 20
    @page = params[:page].to_i > 0 ? params[:page].to_i : 1
    offset = (@page - 1) * per_page

    tournaments = if params[:search].present?
      Tournament.search_date_name(params[:search])
    else
      Tournament.all
    end

    @total_count = tournaments.count
    @total_pages = (@total_count / per_page.to_f).ceil
    @per_page = per_page

    tournaments_table = Tournament.arel_table
    date_distance = Arel::Nodes::NamedFunction.new(
      "ABS",
      [tournaments_table[:date_sort_key] - Date.current.jd]
    )

    @tournaments = tournaments
      .order(date_distance.asc, tournaments_table[:date].asc, tournaments_table[:id].asc)
      .offset(offset)
      .limit(per_page)
  end

  def show
    @tournament = Tournament.find(params[:id])
    @schools = @tournament.schools.includes(:delegates).sort_by{|school|school.name}
    @weights = @tournament.weights.includes(:wrestlers).sort_by{|x|[x.max]}
    @mats = @tournament.mats.sort_by{|mat|mat.name}
  end

  def new
    @tournament = Tournament.new
  end

  def edit
  end

  def create
    if user_signed_in?
    else
      redirect_to root_path
    end
    @tournament = Tournament.new(tournament_params)
    @tournament.user_id = current_user.id
    respond_to do |format|
      if @tournament.save
        format.html { redirect_to @tournament, notice: 'Tournament was successfully created.' }
        format.json { render action: 'show', status: :created, location: @tournament }
      else
        format.html { render action: 'new' }
        format.json { render json: @tournament.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @tournament.update(tournament_params)
        format.html { redirect_to @tournament, notice: 'Tournament was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @tournament.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @tournament.destroy_with_dependents!
    respond_to do |format|
      format.html { redirect_to tournaments_url }
      format.json { head :no_content }
    end
  end

  def error
  end

  def reset_bout_board
    @tournament.reset_and_fill_bout_board
    redirect_to tournament_path(@tournament), notice: "Successfully reset the bout board. Please have all mat table workers refresh their page."
  end

  def generate_school_keys
    @tournament.schools.each do |school|
      school.update(permission_key: SecureRandom.uuid)
    end
    redirect_to school_delegate_path(@tournament), notice: "School permission keys generated successfully."
  end

  def delete_school_keys
    @tournament.schools.update_all(permission_key: nil)
    redirect_to school_delegate_path(@tournament), notice: "All school permission keys have been deleted."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tournament
      @tournament = if action_name == "live_scores"
        Tournament.find_by(id: params[:id])
      elsif %w[bracket all_brackets team_scores].include?(action_name)
        Tournament.includes(:user, :delegates).find_by(id: params[:id])
      else
        Tournament.includes(:user, :delegates, :mats, :schools, :weights, :matches, wrestlers: [:school, :weight, :matches_as_w1, :matches_as_w2]).find_by(id: params[:id])
      end
    end

    def cached_team_scores
      Rails.cache.fetch(TournamentCacheInvalidator.team_scores_data_key(@tournament.id)) do
        @tournament.schools.map do |school|
          {
            id: school.id,
            name: school.name,
            abbreviation: school.abbreviation,
            score: school.page_score_string
          }
        end.sort_by { |school| [-school[:score].to_f, school[:name]] }
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def tournament_params
      params.require(:tournament).permit(:name, :address, :director, :director_email, :tournament_type, :weigh_in_ref, :date, :originalId, :swapId, :is_public)
    end

  #Check for tournament owner
  def check_access_destroy
    authorize! :destroy, @tournament
  end

  def check_access_manage
    authorize! :manage, @tournament
  end

  def check_access_read
    authorize! :read, @tournament
  end

  def check_for_matches
    if @tournament
    	if @tournament.matches.empty? or @tournament.curently_generating_matches == 1
    	  redirect_to "/tournaments/#{@tournament.id}/no_matches"
    	end
    end
  end

  def check_tournament_errors
    if @tournament.match_generation_error != nil
      respond_to do |format|
        format.html { redirect_to "/tournaments/#{@tournament.id}/error" }
      end
    end
  end

end
