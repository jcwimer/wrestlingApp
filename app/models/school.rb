class School < ActiveRecord::Base
	belongs_to :tournament
	has_many :wrestlers, dependent: :destroy
	

	#calculate score here
	def score
		#Add score per wrestler. Calculate score in wrestler model.
		return 0
	end
end
