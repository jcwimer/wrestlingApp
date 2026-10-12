# frozen_string_literal: true

class TournamentPostsController < ApplicationController
  before_action :set_tournament
  before_action :check_access
  before_action :set_tournament_post, only: %i[edit update destroy email_coaches]

  def index
    @tournament_posts = @tournament.tournament_posts.order(created_at: :desc, id: :desc)
  end

  def new
    @tournament_post = @tournament.tournament_posts.build
  end

  def edit; end

  def create
    @tournament_post = @tournament.tournament_posts.build(tournament_post_params)
    if @tournament_post.save
      redirect_to tournament_tournament_posts_path(@tournament), notice: saved_notice('saved')
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @tournament_post.update(tournament_post_params)
      redirect_to tournament_tournament_posts_path(@tournament), notice: saved_notice('updated')
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @tournament_post.destroy!
    redirect_to tournament_tournament_posts_path(@tournament), notice: 'Tournament update deleted.'
  end

  def email_coaches
    redirect_to tournament_tournament_posts_path(@tournament), notice: queue_coach_emails
  end

  private

  def set_tournament
    @tournament = Tournament.includes(:delegates).find(params[:tournament_id])
  end

  def check_access
    authorize! :manage, @tournament
  end

  def set_tournament_post
    @tournament_post = @tournament.tournament_posts.find(params[:id])
  end

  def tournament_post_params
    params.require(:tournament_post).permit(:title, :body, :is_public)
  end

  def saved_notice(action)
    notice = "Tournament update #{action}."
    notice += " #{queue_coach_emails}" if ActiveModel::Type::Boolean.new.cast(params[:email_coaches])
    notice
  end

  def queue_coach_emails
    schools = @tournament.schools.where.not(email: [nil, ''])
    count = 0
    schools.find_each do |school|
      EmailTournamentPostJob.perform_later_with_enqueue_retry(@tournament_post.id, school.id)
      count += 1
    end
    if count.zero?
      'No emails queued: no schools have an email address.'
    else
      "Emails queued for #{count} #{'school'.pluralize(count)}. Schools without an email address are skipped."
    end
  end
end
