class School < ActiveRecord::Base
	belongs_to :tournament
	has_many :wrestlers, dependent: :destroy
	

	#calculate score here
	def score
		return 0
	end
end
