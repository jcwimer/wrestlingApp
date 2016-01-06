class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  has_many :tournaments
  has_many :delegated_tournaments, class_name: "TournamentDelegate"
  has_many :delegated_schools, class_name: "SchoolDelegate"

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
         
end
