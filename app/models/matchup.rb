class Matchup
	attr_accessor :w1, :w2, :round, :weight_id

	# def w1
	# end

	# def w2
	# end

	# def round
	# end

	# def weight_id
	# end

	def weight_max
		@wrestler = Wrestler.find(self.w1)
		@weight = Weight.find(@wrestler.weight_id)
		return @weight.max
	end

	def w_name(id)
		@wrestler = Wrestler.find(id)
		return @wrestler.name
	end
end