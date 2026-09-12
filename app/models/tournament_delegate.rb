# frozen_string_literal: true

class TournamentDelegate < ApplicationRecord
  belongs_to :tournament
  belongs_to :user
end
