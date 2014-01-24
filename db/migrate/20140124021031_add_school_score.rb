class AddSchoolScore < ActiveRecord::Migration
  def change
  	add_column :schools, :score, :integer
  end
end
