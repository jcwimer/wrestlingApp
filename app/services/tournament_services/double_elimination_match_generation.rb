class DoubleEliminationMatchGeneration
  def initialize( tournament )
      @tournament = tournament
    end

    def generate_matches
      @tournament.weights.each do |weight|
      	SixteenManDoubleEliminationMatchGeneration.new(weight).generate_matches_for_weight if weight.wrestlers.size >= 9 and weight.wrestlers.size <= 16
      	EightManDoubleEliminationMatchGeneration.new(weight).generate_matches_for_weight if weight.wrestlers.size >= 4 and weight.wrestlers.size <= 8
      end
    end
end