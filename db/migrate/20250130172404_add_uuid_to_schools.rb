class AddUuidToSchools < ActiveRecord::Migration[7.2]
  def change
    add_column :schools, :permission_key, :string
    add_index :schools, :permission_key, unique: true
  end
end
