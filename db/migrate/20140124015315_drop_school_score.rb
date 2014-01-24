class DropSchoolScore < ActiveRecord::Migration
  def change
  	remove_column :schools, :score
  end
end
