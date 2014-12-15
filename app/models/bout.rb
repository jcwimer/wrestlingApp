class Bout
	attr_accessor :w1, :w2, :tournament_id
	def self.all
    	ObjectSpace.each_object(self).to_a
  	end
  	
  	def self.count
    	all.count
  	end

end