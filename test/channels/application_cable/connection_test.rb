require "test_helper"

module ApplicationCable
  class ConnectionTest < ActionCable::Connection::TestCase
    test "connects current user from session" do
      connect session: { user_id: users(:one).id }

      assert_equal users(:one), connection.current_user
    end

    test "connects anonymously without a session user" do
      connect

      assert_nil connection.current_user
    end
  end
end
