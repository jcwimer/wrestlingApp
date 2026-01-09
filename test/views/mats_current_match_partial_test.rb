require "test_helper"

class MatsCurrentMatchPartialTest < ActionView::TestCase
  include ActionView::RecordIdentifier

  test "renders current match contents when assigned" do
    create_double_elim_tournament_single_weight_1_6(4)
    mat = @tournament.mats.create!(name: "Mat 1")
    match = @tournament.matches.first

    match.update!(mat: mat)

    render partial: "mats/current_match", locals: { mat: mat }

    assert_includes rendered, "Bout"
    assert_includes rendered, match.bout_number.to_s
    assert_includes rendered, mat.name
  end

  test "renders friendly message when no matches assigned" do
    create_double_elim_tournament_single_weight_1_6(4)
    mat = @tournament.mats.create!(name: "Mat 1")
    @tournament.matches.update_all(mat_id: nil)

    render partial: "mats/current_match", locals: { mat: mat }

    assert_includes rendered, "No matches assigned to this mat."
  end
end
