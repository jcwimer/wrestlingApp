# frozen_string_literal: true

class AddSchoolEmailAndTournamentPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :schools, :email, :string

    create_table :tournament_posts do |t|
      t.references :tournament, type: :bigint, null: false, foreign_key: true
      t.string :title, null: false
      t.text :body, null: false
      t.timestamps
    end
  end
end
