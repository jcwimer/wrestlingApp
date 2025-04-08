namespace :auth do
  desc "Migrate from Devise to Rails Authentication"
  task migrate: :environment do
    puts "Running Authentication Migration"
    puts "================================"
    
    # Run the migrations
    Rake::Task["db:migrate"].invoke
    
    # Ensure all existing users have a password_digest value
    users_without_digest = User.where(password_digest: nil)
    
    if users_without_digest.any?
      puts "Setting password_digest for #{users_without_digest.count} users..."
      
      ActiveRecord::Base.transaction do
        users_without_digest.each do |user|
          if user.encrypted_password.present?
            # Copy Devise's encrypted_password to password_digest
            # This works because both use bcrypt in the same format
            user.update_column(:password_digest, user.encrypted_password)
            print "."
          else
            puts "\nWARNING: User #{user.id} (#{user.email}) has no encrypted_password!"
          end
        end
      end
      puts "\nDone!"
    else
      puts "All users already have a password_digest."
    end
    
    puts "Migration complete."
  end
end 