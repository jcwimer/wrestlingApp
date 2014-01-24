class Wrestler < ActiveRecord::Base
	belongs_to :school
	belongs_to :weight
	has_many :matches
end
