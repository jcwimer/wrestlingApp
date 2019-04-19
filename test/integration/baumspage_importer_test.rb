require 'test_helper'

class BaumspageImporterTest < ActionDispatch::IntegrationTest
  def setup
    create_pool_tournament
    #Needs 106-126 or test will fail
    @school = @tournament.schools.sample
    @baums_text = "***** 2019-01-09 13:36:50 *****
Some School
Some Guy
106,,,,,,,,,
113,Guy,Another,9,,,,,5,7
120,Guy2,Another,9,,,,,0,0
126,Guy3,Another,10,,,,5@120,2,2
******* Extra Wrestlers *******
120,Guy4,Another,10,0,3
126,Guy5,Another,9,,"
  end

  test "5 wrestlers get created with Baumspage Importer" do
    BaumspageRosterImport.new(@school,@baums_text).import_roster
    assert @school.reload.wrestlers.size == 5
    extras = @school.wrestlers.select{|w| w.extra == true}
    assert extras.size == 2
    guy = @school.wrestlers.select{|w| w.name == "Another Guy"}.first
    assert guy.season_win == 5
    assert guy.season_loss == 7
    guy5 = @school.wrestlers.select{|w| w.name == "Another Guy5"}.first
    assert guy5.season_win == 0
    assert guy5.season_loss == 0
  end

end