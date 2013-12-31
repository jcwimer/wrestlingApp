class Wrestler < ActiveRecord::Base
	belongs_to :school
	belongs_to :weight
end
