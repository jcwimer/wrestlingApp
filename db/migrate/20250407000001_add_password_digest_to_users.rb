class AddPasswordDigestToUsers < ActiveRecord::Migration[6.1]
  def change
    # Add password_digest column if it doesn't already exist
    add_column :users, :password_digest, :string unless column_exists?(:users, :password_digest)
    
    # If we're migrating from Devise, we need to convert encrypted_password to password_digest
    # This is a data migration that will preserve the passwords
    reversible do |dir|
      dir.up do
        # Only perform if both columns exist
        if column_exists?(:users, :encrypted_password) && column_exists?(:users, :password_digest)
          execute <<-SQL
            -- Copy over the encrypted_password to password_digest column for all users
            -- Devise uses the same bcrypt format that has_secure_password expects
            UPDATE users SET password_digest = encrypted_password WHERE password_digest IS NULL;
          SQL
        end
      end
    end
  end
end 