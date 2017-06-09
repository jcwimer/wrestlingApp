class AddScoreBackToSchool < ActiveRecord::Migration[4.2]
  def change
  	add_column :schools, :score, :decimal
  end
end
