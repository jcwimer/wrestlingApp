class IntroduceIndexes < ActiveRecord::Migration
  def change
    add_index :weights, :tournament_id
    add_index :schools, :tournament_id
    add_index :mats, :tournament_id
    add_index :matches, :tournament_id
    add_index :matches, [:w1, :w2], :unique => true
    add_index :wrestlers, :weight_id
  end
end
