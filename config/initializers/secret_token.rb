# Be sure to restart your server when you modify this file.

# Your secret key is used for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!

# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
# You can use `rake secret` to generate a secure secret key.

# Make sure your secret_key_base is kept private
# if you're sharing your code publicly.
if Rails.env.production?
  Wrestling::Application.config.secret_key_base = ENV['WRESTLINGDEV_SECRET_KEY_BASE'] 
else 
  Wrestling::Application.config.secret_key_base = "077cdbef5c2ccf22543fb17a67339f234306b7fa2e1e4463d851c444c10a5611829a2290b253da78339427f131571fac9a42c83d960b2d25ecc10a4a0a7ce1a2"
end
