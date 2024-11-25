class MatAssignmentRule < ApplicationRecord
    belongs_to :mat
    belongs_to :tournament
  end