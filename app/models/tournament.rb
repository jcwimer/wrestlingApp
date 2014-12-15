class Tournament < ActiveRecord::Base
	has_many :schools, dependent: :destroy
	has_many :weights, dependent: :destroy
	has_many :matches, dependent: :destroy
	has_many :mats, dependent: :destroy	

	def bouts
		@pool = Pool.new
	    @pool.createPool(self.id)
	    @bouts = Bout.all
	    return @bouts
	end
end
