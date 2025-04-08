class User < ApplicationRecord
  attr_accessor :reset_token
  
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  has_many :tournaments
  has_many :delegated_tournament_permissions, class_name: "TournamentDelegate"
  has_many :delegated_school_permissions, class_name: "SchoolDelegate"

  # Replace Devise with has_secure_password
  has_secure_password

  # Add validations that were handled by Devise
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 6 }, allow_nil: true

  # These are the Devise modules we were using:
  # devise :database_authenticatable, :registerable,
  #        :recoverable, :rememberable, :trackable, :validatable

  # Returns the hash digest of the given string
  def self.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  # Returns a random token
  def self.new_token
    SecureRandom.urlsafe_base64
  end

  # Sets the password reset attributes
  def create_reset_digest
    self.reset_token = User.new_token
    update_columns(reset_digest: User.digest(reset_token), reset_sent_at: Time.zone.now)
  end

  # Sends password reset email
  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  # Returns true if a password reset has expired
  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end

  # Returns true if the given token matches the digest
  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  def delegated_tournaments
    tournaments_delegated = []
    delegated_tournament_permissions.each do |t|
      tournaments_delegated << t.tournament
    end
    tournaments_delegated
  end
  
  def delegated_schools
    schools_delegated = []
    delegated_school_permissions.each do |t|
      schools_delegated << t.school
    end
    schools_delegated
  end
  
  def self.search(search)
	  where("email LIKE ?", "%#{search}%")
	end      
end
