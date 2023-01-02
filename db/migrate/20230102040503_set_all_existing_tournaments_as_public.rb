class SetAllExistingTournamentsAsPublic < ActiveRecord::Migration[6.1]
  def up
    Tournament.update_all(is_public: true)
  end

  def down
    Tournament.update_all(is_public: nil)
  end
end
