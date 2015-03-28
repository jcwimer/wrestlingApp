class DropSchoolScoreAgain < ActiveRecord::Migration
  def change
  	remove_column :schools, :score
  end
end
