class DoubleEliminationGenerateLoserNames
	def initialize( tournament )
      @tournament = tournament
    end

    def assign_loser_names
      @tournament.weights.each do |weight|
      	SixteenManDoubleEliminationGenerateLoserNames.new(weight).assign_loser_names_for_weight if weight.wrestlers.size >= 9 and weight.wrestlers.size <= 16
      	EightManDoubleEliminationGenerateLoserNames.new(weight).assign_loser_names_for_weight if weight.wrestlers.size >= 4 and weight.wrestlers.size <= 8
      end
    end

end