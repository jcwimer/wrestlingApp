class AddScoreBackToSchool < ActiveRecord::Migration
  def change
  	add_column :schools, :score, :decimal
  end
end
