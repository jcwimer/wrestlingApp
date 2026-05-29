module ApplicationCable
  class Channel < ActionCable::Channel::Base
    private

    def current_ability
      @current_ability ||= Ability.new(connection_current_user)
    end

    def can?(action, subject)
      current_ability.can?(action, subject)
    end

    def connection_current_user
      connection.current_user if connection.respond_to?(:current_user)
    end
  end
end
