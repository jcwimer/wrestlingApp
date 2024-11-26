class MatAssignmentRule < ApplicationRecord
  belongs_to :mat
  belongs_to :tournament

  # Ensure default values for JSON fields
  # because mysql doesn't allow this
  after_initialize do
    self.weight_classes ||= []
    self.bracket_positions ||= []
    self.rounds ||= []
  end
end
