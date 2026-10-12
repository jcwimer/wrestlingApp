# frozen_string_literal: true

class TournamentPost < ApplicationRecord
  belongs_to :tournament

  validates :title, :body, presence: true
  validates :title, length: { maximum: 255 }
end
