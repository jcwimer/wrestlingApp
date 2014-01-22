class School < ActiveRecord::Base
	belongs_to :tournament
	has_many :wrestlers
end
