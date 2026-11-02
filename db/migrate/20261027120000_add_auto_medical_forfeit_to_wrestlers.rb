# frozen_string_literal: true

class AddAutoMedicalForfeitToWrestlers < ActiveRecord::Migration[8.1]
  def change
    add_column :wrestlers, :auto_medical_forfeit, :boolean, default: false, null: false
  end
end
