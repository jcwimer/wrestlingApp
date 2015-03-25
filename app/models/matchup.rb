class Matchup
	attr_accessor :w1, :w2, :round, :weight_id, :boutNumber, :w1_name, :w2_name, :bracket_position, :bracket_position_number

	def weight_max
		@weight = Weight.find(self.weight_id)
		return @weight.max
	end
	
	def to_hash
    	hash = {}
    	instance_variables.each {|var| hash[var.to_s.delete("@")] = instance_variable_get(var) }
    	hash
  	end
  	
  	def convert_to_obj(h)
	 h.each do |k,v|
     	self.class.send(:attr_accessor, k)
     	instance_variable_set("@#{k}", v) 
     	convert_to_obj(v) if v.is_a? Hash
     end	
    end


end