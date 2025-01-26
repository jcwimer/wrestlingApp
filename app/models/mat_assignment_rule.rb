class MatAssignmentRule < ApplicationRecord
  belongs_to :mat
  belongs_to :tournament

  # Convert comma-separated values to arrays
  def weight_classes
    (super || "").split(",").map(&:to_i)
  end

  def weight_classes=(value)
    super(value.is_a?(Array) ? value.join(",") : value)
  end

  def bracket_positions
    (super || "").split(",")
  end

  def bracket_positions=(value)
    super(value.is_a?(Array) ? value.join(",") : value)
  end

  def rounds
    (super || "").split(",").map(&:to_i)
  end

  def rounds=(value)
    super(value.is_a?(Array) ? value.join(",") : value)
  end
end
