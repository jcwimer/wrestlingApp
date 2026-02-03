class AddQueuesToMats < ActiveRecord::Migration[7.0]
  class Mat < ActiveRecord::Base
    self.table_name = "mats"
    has_many :matches, class_name: "AddQueuesToMats::Match", foreign_key: "mat_id"
  end

  class Match < ActiveRecord::Base
    self.table_name = "matches"
  end

  def up
    add_column :mats, :queue1, :bigint
    add_column :mats, :queue2, :bigint
    add_column :mats, :queue3, :bigint
    add_column :mats, :queue4, :bigint

    add_index :mats, :queue1
    add_index :mats, :queue2
    add_index :mats, :queue3
    add_index :mats, :queue4

    say_with_time "Backfilling mat queues from unfinished matches" do
      Mat.reset_column_information
      Match.reset_column_information

      Mat.find_each do |mat|
        match_ids = mat.matches.where(finished: [nil, 0]).order(:bout_number).limit(4).pluck(:id)
        mat.update_columns(
          queue1: match_ids[0],
          queue2: match_ids[1],
          queue3: match_ids[2],
          queue4: match_ids[3]
        )
      end
    end
  end

  def down
    remove_index :mats, :queue1
    remove_index :mats, :queue2
    remove_index :mats, :queue3
    remove_index :mats, :queue4

    remove_column :mats, :queue1
    remove_column :mats, :queue2
    remove_column :mats, :queue3
    remove_column :mats, :queue4
  end
end
