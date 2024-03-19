class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  has_many :tournaments
  has_many :delegated_tournament_permissions, class_name: "TournamentDelegate"
  has_many :delegated_school_permissions, class_name: "SchoolDelegate"

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

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
