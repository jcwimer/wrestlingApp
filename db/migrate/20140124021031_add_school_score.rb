class AddSchoolScore < ActiveRecord::Migration[4.2]
  def change
  	add_column :schools, :score, :integer
  end
end
