class AddResetColumnsToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :reset_digest, :string unless column_exists?(:users, :reset_digest)
    add_column :users, :reset_sent_at, :datetime unless column_exists?(:users, :reset_sent_at)
  end
end 