# frozen_string_literal: true

module SchoolServices
  class CalculateSchoolScore
    def initialize(school)
      @school = school
    end

    def calculate
      school = preload_school_context
      score = calculate_score_value(school)
      persist_school_score(school.id, score)
      score
    end

    def calculate_value
      school = preload_school_context
      calculate_score_value(school)
    end

    private

    def preload_school_context
      School
        .includes(
          :deductedPoints,
          wrestlers: [
            :deductedPoints,
            { matches_as_w1: :winner },
            { matches_as_w2: :winner },
            { weight: [:matches, { tournament: { weights: :wrestlers } }] }
          ]
        )
        .find(@school.id)
    end

    def calculate_score_value(school)
      total_points_scored_by_wrestlers(school) - total_points_deducted(school)
    end

    def total_points_scored_by_wrestlers(school)
      school.wrestlers.sum { |wrestler| WrestlerServices::CalculateWrestlerTeamScore.new(wrestler).total_score }
    end

    def total_points_deducted(school)
      school.deductedPoints.sum(&:points)
    end

    def persist_school_score(school_id, score)
      School.upsert_all([
                          {
                            id: school_id,
                            score: score,
                            updated_at: Time.current
                          }
                        ])
    end
  end
end
