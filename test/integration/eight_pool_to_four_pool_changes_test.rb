require 'test_helper'

class EightPoolToFourPoolChangesTest < ActionDispatch::IntegrationTest
  def setup
    create_pool_tournament_single_weight(24)
  end

  test "All wrestlers get matches after a weight switches from 8 pool to 4 pool" do
    assert @tournament.matches.count == 36
    assert @tournament.weights.first.pools == 8
    count = 1
    @tournament.reload.weights.first.wrestlers.sort_by{|wrestler| wrestler.pool}.each do |wrestler|
      if count <= 8
        wrestler.destroy
        count =  count + 1
      end
    end
    GenerateTournamentMatches.new(@tournament.reload).generate
    assert @tournament.matches.count == 32
    assert @tournament.weights.first.pools == 4
    @tournament.reload.weights.first.wrestlers.each do |wrestler|
      assert wrestler.pool <= 4
      assert wrestler.all_matches.count > 0
    end
  end
end