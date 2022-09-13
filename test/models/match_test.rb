require 'test_helper'

class MatchTest < ActiveSupport::TestCase
   test "Match should not be valid if win type is a pin and a score is provided" do
     create_double_elim_tournament_single_weight(14, "Regular Double Elimination 1-8")
     matches = @tournament.matches.reload
     round1 = matches.select{|m| m.round == 1}
     match = matches.first
     match.winner_id = match.w1
     match.finished = 1
     match.win_type = "Pin"
     match.score = "0-0"
     match.save
     assert !match.valid?
   end
   test "Match should not be valid if win type is a pin and an incorrect time is provided" do
     create_double_elim_tournament_single_weight(14, "Regular Double Elimination 1-8")
     matches = @tournament.matches.reload
     round1 = matches.select{|m| m.round == 1}
     match = matches.first
     match.winner_id = match.w1
     match.finished = 1
     match.win_type = "Pin"
     match.score = ":03"
     match.save
     assert !match.valid?
   end
   test "Match should be valid if win type is a pin and a correct time is provided" do
     create_double_elim_tournament_single_weight(14, "Regular Double Elimination 1-8")
     matches = @tournament.matches.reload
     round1 = matches.select{|m| m.round == 1}
     match = matches.first
     match.winner_id = match.w1
     match.finished = 1
     match.win_type = "Pin"
     match.score = "0:03"
     match.save
     assert match.valid?
   end
   test "Match should be valid if win type is a pin and a correct time is provided with an extra 0" do
     create_double_elim_tournament_single_weight(14, "Regular Double Elimination 1-8")
     matches = @tournament.matches.reload
     round1 = matches.select{|m| m.round == 1}
     match = matches.first
     match.winner_id = match.w1
     match.finished = 1
     match.win_type = "Pin"
     match.score = "00:03"
     match.save
     assert match.valid?
   end
   test "Match should be valid if win type is a decision and a correct score is provided" do
     create_double_elim_tournament_single_weight(14, "Regular Double Elimination 1-8")
     matches = @tournament.matches.reload
     round1 = matches.select{|m| m.round == 1}
     match = matches.first
     match.winner_id = match.w1
     match.finished = 1
     match.win_type = "Decision"
     match.score = "1-0"
     match.save
     assert match.valid?
   end
   test "Match should not be valid if win type is a decision and a time is provided" do
     create_double_elim_tournament_single_weight(14, "Regular Double Elimination 1-8")
     matches = @tournament.matches.reload
     round1 = matches.select{|m| m.round == 1}
     match = matches.first
     match.winner_id = match.w1
     match.finished = 1
     match.win_type = "Decision"
     match.score = "1:00"
     match.save
     assert !match.valid?
   end
   test "Match should not be valid if win type is a bye and a score is provided" do
     create_double_elim_tournament_single_weight(14, "Regular Double Elimination 1-8")
     matches = @tournament.matches.reload
     round1 = matches.select{|m| m.round == 1}
     match = matches.first
     match.winner_id = match.w1
     match.finished = 1
     match.win_type = "BYE"
     match.score = "1:00"
     match.save
     assert !match.valid?
   end
   test "Match should be valid if win type is a bye and a score is not provided" do
     create_double_elim_tournament_single_weight(14, "Regular Double Elimination 1-8")
     matches = @tournament.matches.reload
     round1 = matches.select{|m| m.round == 1}
     match = matches.first
     match.winner_id = match.w1
     match.finished = 1
     match.win_type = "BYE"
     match.score = ""
     match.save
     assert match.valid?
   end
   test "Match should not be valid if an incorrect win type is given" do
     create_double_elim_tournament_single_weight(14, "Regular Double Elimination 1-8")
     matches = @tournament.matches.reload
     round1 = matches.select{|m| m.round == 1}
     match = matches.first
     match.winner_id = match.w1
     match.finished = 1
     match.win_type = "TEST"
     match.save
     assert !match.valid?
   end
   test "Match should not be valid if an incorrect bracket position is given" do
     create_double_elim_tournament_single_weight(14, "Regular Double Elimination 1-8")
     matches = @tournament.matches.reload
     round1 = matches.select{|m| m.round == 1}
     match = matches.first
     match.bracket_position = "TEST"
     match.save
     assert !match.valid?
   end
   test "Match should not be valid if an incorrect overtime_type is given" do
     create_double_elim_tournament_single_weight(14, "Regular Double Elimination 1-8")
     matches = @tournament.matches.reload
     round1 = matches.select{|m| m.round == 1}
     match = matches.first
     match.overtime_type = "TEST"
     match.save
     assert !match.valid?
   end
end
