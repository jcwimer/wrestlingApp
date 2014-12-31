class Weight < ActiveRecord::Base
	belongs_to :tournament
	has_many :wrestlers, dependent: :destroy

	attr_accessor :pools

	def generatePool
		@wrestlers = Wrestler.where(weight_id: self.id)
		if self.pools == 1
			onePool(@wrestlers)
		elsif self.pools == 2
			
		elsif self.pools == 4
			
		end
	end

	def pools
		@wrestlers = Wrestler.where(weight_id: self.id)
		if @wrestlers.size <= 5
			self.pools = 1
		elsif  (@wrestlers.size > 5) && (@wrestlers.size <= 8)
			self.pools = 2
		elsif (@wrestlers.size > 8) && (@wrestlers.size <= 16)
			self.pools = 4
		end
	end

	def fourPool

	end
	
	def onePool(wrestlers)
		wrestlers.each do |wrestler|
			wrestler.poolNumber = 1
			wrestler.save
		end
	end


end
