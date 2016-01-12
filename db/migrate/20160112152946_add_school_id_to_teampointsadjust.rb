class AddSchoolIdToTeampointsadjust < ActiveRecord::Migration
  def change
    add_column :teampointadjusts, :school_id, :integer
  end
end
