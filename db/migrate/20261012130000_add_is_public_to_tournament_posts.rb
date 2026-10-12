# frozen_string_literal: true

class AddIsPublicToTournamentPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :tournament_posts, :is_public, :boolean, default: false, null: false
  end
end
