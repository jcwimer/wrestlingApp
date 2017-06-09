class AddSchoolIdToTeampointsadjust < ActiveRecord::Migration[4.2]
  def change
    add_column :teampointadjusts, :school_id, :integer
  end
end
