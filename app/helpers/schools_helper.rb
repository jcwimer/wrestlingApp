module SchoolsHelper
  def school_roster
    @school_roster ||= begin
      wrestlers = if @tournament.tournament_type == "Pool to bracket"
        ActiveRecord::Associations::Preloader.new(
          records: [@tournament],
          associations: { weights: { wrestlers: [
            :school, :deductedPoints, { matches_as_w1: :mat }, { matches_as_w2: :mat }
          ] } }
        ).call
        @tournament.weights.flat_map(&:wrestlers).select { |wrestler| wrestler.school_id == @school.id }
      else
        @school.wrestlers.includes(
          :school, :deductedPoints,
          { weight: [:tournament, :matches] },
          { matches_as_w1: :mat }, { matches_as_w2: :mat }
        ).to_a
      end
      wrestlers.sort_by { |wrestler| wrestler.weight.max }
    end
  end
end
