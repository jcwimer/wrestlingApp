class IndexesMatchesWeightidWrestlersSchoolid < ActiveRecord::Migration[6.1]
  def change
    add_index :matches, :weight_id
    add_index :wrestlers, :school_id
  end
end
