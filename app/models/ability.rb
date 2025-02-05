class Ability
  include CanCan::Ability

  def initialize(user, school_permission_key = nil)
    if user
      # Can manage tournament if tournament owner
      can :manage, Tournament, user_id: user.id

      # Can manage but cannot destroy tournament if tournament delegate
      can :manage, Tournament do |tournament|
        tournament.delegates.map(&:user_id).include?(user.id)
      end
      cannot :destroy, Tournament do |tournament|
        tournament.delegates.map(&:user_id).include?(user.id)
      end

      # Can read tournament if tournament owner or tournament delegate
      can :read, Tournament do |tournament|
        tournament.is_public || tournament.delegates.map(&:user_id).include?(user.id) || tournament.user_id == user.id
      end

      # Can manage school if tournament owner
      can :manage, School do |school|
        school.tournament.user_id == user.id
      end

      # Can manage school if tournament delegate
      can :manage, School do |school|
        school.tournament.delegates.map(&:user_id).include?(user.id)
      end

      # Can manage but cannot destroy school if school delegate
      can :manage, School do |school|
        school.delegates.map(&:user_id).include?(user.id)
      end
      cannot :destroy, School do |school|
        school.delegates.map(&:user_id).include?(user.id)
      end

      # Can read school if school delegate, tournament delegate, or tournament director
      can :read, School do |school|
        school.tournament.is_public || 
        school.delegates.map(&:user_id).include?(user.id) || 
        school.tournament.delegates.map(&:user_id).include?(user.id) || 
        school.tournament.user_id == user.id
      end
    else
      # Default permissions for non-logged-in users

      # Can read tournament if tournament is public
      can :read, Tournament do |tournament|
        tournament.is_public
      end

      # Can read school if tournament is public
      can :read, School do |school|
        school.tournament.is_public
      end

      # Allow management of school if valid school_permission_key is provided
      if school_permission_key.present?
        can :manage, School do |school|
          school.permission_key == school_permission_key
        end
      end
    end
  end
end
