class Mat < ActiveRecord::Base
	belongs_to :tournament
	has_many :weights, dependent: :destroy
end
