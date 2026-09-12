# frozen_string_literal: true

class TournamentBackup < ApplicationRecord
  belongs_to :tournament

  validates :backup_data, presence: true
end
