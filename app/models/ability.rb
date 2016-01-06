class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
    if !user.nil?
      #Can manage tournament if tournament owner
      can :manage, Tournament, :user_id => user.id
      #Can manage but cannot destroy tournament if tournament delegate
      can :manage, Tournament do |tournament|
        tournament.delegates.map(&:user_id).include? user.id
      end
      cannot :destroy, Tournament do |tournament|
        tournament.delegates.map(&:user_id).include? user.id
      end
      #Can manage school if tournament owner
      can :manage, School do |school|
        school.tournament.map(&:user_id).include? user.id
      end
      #Can manage school if tournament delegate
      can :manage, School do |school|
        school.tournament.delegates.map(&:user_id).include? user.id
      end
      #Can manage but cannot destroy school if school delegate
      can :manage, School do |school|
        school.delegates.map(&:user_id).include? user.id
      end
      cannot :destroy, School do |school|
        school.delegates.map(&:user_id).include? user.id
      end
    end
  end
end
