class CreateSchoolDelegates < ActiveRecord::Migration[4.2]
  def change
    create_table :school_delegates do |t|
      t.integer :user_id
      t.integer :school_id

      t.timestamps null: false
    end
  end
end
