# frozen_string_literal: true

module BracketAdvancement
  class AutomaticResults
    def initialize(weight)
      @weight = weight
    end

    def call
      Match.transaction do
        @weight.tournament.mats.order(:id).lock.load
        @weight.matches.where(finished: [nil, 0]).order(:id).lock.includes(:wrestler1, :wrestler2).each do |match|
          result = result_for(match)
          next unless result

          match.update!(result.merge(finished: 1, score: '', overtime_type: nil))
          break
        end
      end
    end

    private

    def result_for(match)
      if match.w1 && match.w2
        wrestlers = [match.wrestler1, match.wrestler2]
        return unless wrestlers.any?(&:auto_medical_forfeit?)

        eligible_winners = wrestlers.reject(&:auto_medical_forfeit?)
        { winner_id: (eligible_winners.presence || wrestlers).sample.id, win_type: 'Medical Forfeit' }
      elsif match.double_bye? || (match.w1 && match.loser2_name == 'BYE') || (match.w2 && match.loser1_name == 'BYE')
        { winner_id: match.w1 || match.w2, win_type: 'BYE' }
      end
    end
  end
end
