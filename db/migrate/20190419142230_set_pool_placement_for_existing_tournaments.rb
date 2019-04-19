class SetPoolPlacementForExistingTournaments < ActiveRecord::Migration[5.2]

  def change

  	Tournament.all.each do | tournament |
      tournament.weights.each do | weight |
        for pool in (1..weight.pools) do
          if weight.all_pool_matches_finished(pool)
            PoolOrder.new(weight.wrestlers_in_pool(pool)).getPoolOrder
          end
        end
      end
    end

  end

end
