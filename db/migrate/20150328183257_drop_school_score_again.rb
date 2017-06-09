class DropSchoolScoreAgain < ActiveRecord::Migration[4.2]
  def change
  	remove_column :schools, :score
  end
end
