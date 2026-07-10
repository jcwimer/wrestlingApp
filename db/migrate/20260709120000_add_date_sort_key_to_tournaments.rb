class AddDateSortKeyToTournaments < ActiveRecord::Migration[8.1]
  class Tournament < ActiveRecord::Base
    self.table_name = "tournaments"
  end

  def up
    add_column :tournaments, :date_sort_key, :integer, null: false, default: 0

    Tournament.reset_column_information
    Tournament.find_each do |tournament|
      tournament.update_columns(date_sort_key: tournament.date.jd) if tournament.date
    end

    change_column_default :tournaments, :date_sort_key, from: 0, to: nil
  end

  def down
    remove_column :tournaments, :date_sort_key
  end
end
