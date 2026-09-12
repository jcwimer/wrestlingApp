# frozen_string_literal: true

require 'test_helper'

class TournamentsRoutingTest < ActionDispatch::IntegrationTest
  test 'match generation requires POST' do
    assert_routing(
      { method: 'post', path: '/tournaments/1/generate_matches' },
      { controller: 'tournaments', action: 'generate_matches', id: '1' }
    )

    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path('/tournaments/1/generate_matches', method: :get)
    end
  end
end
