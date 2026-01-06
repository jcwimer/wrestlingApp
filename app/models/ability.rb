class Ability
  include CanCan::Ability

  def school_permission_key_check(school_permission_key)
    # Can read school if tournament is public or a valid school permission key is provided
    can :read, School do |school|
      school.tournament.is_public ||
      (school_permission_key.present? && school.permission_key == school_permission_key)
    end

    # Can manage school if a valid school permission key is provided
    # school_permission_key comes from app/controllers/application_controller.rb
    can :manage, School do |school|
      (school_permission_key.present? && school.permission_key == school_permission_key)
    end
  end

  def initialize(user, school_permission_key = nil)
    if user
      # LOGGED IN USER PERMISSIONS
      
      # TOURNAMENT PERMISSIONS

      # Can manage but cannot destroy tournament if tournament delegate
      can :manage, Tournament do |tournament|
        tournament.user_id == user.id ||
        tournament.delegates.map(&:user_id).include?(user.id)
      end

      # can destroy tournament if tournament owner
      can :destroy, Tournament do |tournament|
        tournament.user_id == user.id
      end
      # tournament delegates cannot destroy - explicitly deny
      cannot :destroy, Tournament do |tournament|
        tournament.delegates.map(&:user_id).include?(user.id)
      end

      # Can read tournament if tournament.is_public, tournament owner, or tournament delegate
      can :read, Tournament do |tournament|
        tournament.is_public ||
        tournament.delegates.map(&:user_id).include?(user.id) ||
        tournament.user_id == user.id
      end

      # SCHOOL PERMISSIONS
      # wrestler permissions are included with school permissions

      # Can manage school if is school delegate, is tournament delegate, or is tournament director
      can :manage, School do |school|
        school.delegates.map(&:user_id).include?(user.id) ||
        school.tournament.delegates.map(&:user_id).include?(user.id) ||
        school.tournament.user_id == user.id
      end

      # Can read school if tournament.is_public OR is school delegate, is tournament delegate, or is tournament director
      can :read, School do |school|
        school.tournament.is_public ||
        school.delegates.map(&:user_id).include?(user.id) ||
        school.tournament.delegates.map(&:user_id).include?(user.id) ||
        school.tournament.user_id == user.id
      end

      school_permission_key_check(school_permission_key)
    else
      # NON LOGGED IN USER PERMISSIONS

      # TOURNAMENT PERMISSIONS

      # Can read tournament if tournament is public
      can :read, Tournament do |tournament|
        tournament.is_public
      end

      # SCHOOL PERMISSIONS
      # wrestler permissions are included with school permissions 
      school_permission_key_check(school_permission_key)
    end
  end
end
