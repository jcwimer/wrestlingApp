class Matchup
	attr_accessor :w1, :w2, :round, :weight_id, :boutNumber, :w1_name, :w2_name

	# def w1
	# end

	# def w2
	# end

	# def round
	# end

	# def weight_id
	# end

	def weight_max
		@weight = Weight.find(self.weight_id)
		return @weight.max
	end

end