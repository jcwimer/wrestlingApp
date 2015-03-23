class Matchup
	attr_accessor :w1, :w2, :round, :weight_id, :boutNumber, :w1_name, :w2_name, :bracket_position, :bracket_position_number

	def weight_max
		@weight = Weight.find(self.weight_id)
		return @weight.max
	end

end