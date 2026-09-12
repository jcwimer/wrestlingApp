# frozen_string_literal: true

class ReconcileFinishedMatchResult
  def initialize(match)
    @match = match
  end

  def call
    @match.advance_wrestlers?
  end
end
