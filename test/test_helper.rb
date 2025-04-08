ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  ActiveRecord::Migration.check_all_pending!

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
  
  # Authentication helpers for tests - replaces Devise test helpers
  def sign_in(user)
    # Set the password_digest for the user if it's not already set
    unless user.password_digest.present?
      user.password_digest = BCrypt::Password.create("password")
      user.save(validate: false)
    end
    
    # For controller tests
    if defined?(@request)
      @request.session[:user_id] = user.id
    end
  end
  
  def create_a_tournament_with_single_weight(tournament_type, number_of_wrestlers)
    @tournament = Tournament.new
    @tournament.name = "Test Tournament"
    @tournament.address = "some place"
    @tournament.director = "some guy"
    @tournament.director_email= "test@test.com"
    @tournament.tournament_type = tournament_type
    @tournament.date = "2015-12-30"
    @tournament.is_public = true
    @tournament.save
    @school = School.new
    @school.name = "Test"
    @school.tournament_id = @tournament.id
    @school.save
    @weight = Weight.new
    @weight.max = 106
    @weight.tournament_id = @tournament.id
    @weight.save
    create_wrestlers_for_weight(@weight, @school, number_of_wrestlers, 1)
    return @tournament
  end

  def create_pool_tournament_single_weight(number_of_wrestlers)
    @tournament = Tournament.new
    @tournament.name = "Test Tournament"
    @tournament.address = "some place"
    @tournament.director = "some guy"
    @tournament.director_email= "test@test.com"
    @tournament.tournament_type = "Pool to bracket"
    @tournament.date = "2015-12-30"
    @tournament.is_public = true
    @tournament.save
    @school = School.new
    @school.name = "Test"
    @school.tournament_id = @tournament.id
    @school.save
    @weight = Weight.new
    @weight.max = 106
    @weight.tournament_id = @tournament.id
    @weight.save
    create_wrestlers_for_weight(@weight, @school, number_of_wrestlers, 1)
    GenerateTournamentMatches.new(@tournament).generate
    return @tournament
  end

  def create_double_elim_tournament_single_weight_1_6(number_of_wrestlers)
    @tournament = Tournament.new
    @tournament.name = "Test Tournament"
    @tournament.address = "some place"
    @tournament.director = "some guy"
    @tournament.director_email= "test@test.com"
    @tournament.tournament_type = "Regular Double Elimination 1-6"
    @tournament.date = "2015-12-30"
    @tournament.is_public = true
    @tournament.save
    @school = School.new
    @school.name = "Test"
    @school.tournament_id = @tournament.id
    @school.save
    @weight = Weight.new
    @weight.max = 106
    @weight.tournament_id = @tournament.id
    @weight.save
    create_wrestlers_for_weight_for_double_elim(@weight, @school, number_of_wrestlers, 1)
    GenerateTournamentMatches.new(@tournament).generate
    return @tournament
  end
  
  def create_double_elim_tournament_single_weight(number_of_wrestlers, tournament_type)
    @tournament = Tournament.new
    @tournament.name = "Test Tournament"
    @tournament.address = "some place"
    @tournament.director = "some guy"
    @tournament.director_email= "test@test.com"
    @tournament.tournament_type = tournament_type
    @tournament.date = "2015-12-30"
    @tournament.is_public = true
    @tournament.save
    @school = School.new
    @school.name = "Test"
    @school.tournament_id = @tournament.id
    @school.save
    @weight = Weight.new
    @weight.max = 106
    @weight.tournament_id = @tournament.id
    @weight.save
    create_wrestlers_for_weight_for_double_elim(@weight, @school, number_of_wrestlers, 1)
    GenerateTournamentMatches.new(@tournament).generate
    return @tournament
  end

  def create_double_elim_tournament_1_6_with_multiple_weights_and_multiple_mats(number_of_wrestlers, number_of_weights, number_of_mats)
    @tournament = Tournament.new
    @tournament.name = "Test Tournament"
    @tournament.address = "some place"
    @tournament.director = "some guy"
    @tournament.director_email = "test@test.com"
    @tournament.tournament_type = "Regular Double Elimination 1-6"
    @tournament.date = "2015-12-30"
    @tournament.is_public = true
    @tournament.save

    @school = School.new
    @school.name = "Test"
    @school.tournament_id = @tournament.id
    @school.save

    @mats = []
    (1..number_of_mats).each do |mat_number|
      mat = Mat.new
      mat.name = "Mat #{mat_number}"
      mat.tournament_id = @tournament.id
      mat.save
      @mats << mat
    end

    (1..number_of_weights).each do |weight_number|
      weight = Weight.new
      weight.max = 100 + weight_number
      weight.tournament_id = @tournament.id
      weight.save
      create_wrestlers_for_weight_for_double_elim(weight, @school, number_of_wrestlers, 1)
    end

    GenerateTournamentMatches.new(@tournament).generate
    return @tournament
  end

  def create_wrestlers_for_weight_for_double_elim(weight, school, number_of_wrestlers, naming_start_number)
    naming_number = naming_start_number
    (1..number_of_wrestlers).each do |number|
      wrestler = Wrestler.new
      wrestler.name = "Test#{naming_number}"
      wrestler.school_id = school.id
      wrestler.weight_id = weight.id
      wrestler.original_seed = naming_number
      wrestler.save
      naming_number += 1
    end
  end

  def create_pool_tournament
    @tournament = Tournament.new
    @tournament.name = "Test Tournament"
    @tournament.address = "some place"
    @tournament.director = "some guy"
    @tournament.director_email= "test@test.com"
    @tournament.tournament_type = "Pool to bracket"
    @tournament.date = "2015-12-30"
    @tournament.is_public = true
    @tournament.save
    
    # First school
    school = School.new
    school.name = "Test1"
    school.tournament_id = @tournament.id
    school.save
    
    # Second school
    school = School.new
    school.name = "Test2"
    school.tournament_id = @tournament.id
    school.save

    # Third school
    school = School.new
    school.name = "Test3"
    school.tournament_id = @tournament.id
    school.save

    # Weight 1
    weight = Weight.new
    weight.max = 106
    weight.tournament_id = @tournament.id
    weight.save
    create_wrestlers_for_weight(weight, @tournament.schools.sample, 6, 1)

    # Weight 2
    weight = Weight.new
    weight.max = 113
    weight.tournament_id = @tournament.id
    weight.save
    create_wrestlers_for_weight(weight, @tournament.schools.sample, 10, 7)

    # Weight 3
    weight = Weight.new
    weight.max = 120
    weight.tournament_id = @tournament.id
    weight.save
    create_wrestlers_for_weight(weight, @tournament.schools.sample, 12, 17)

    # Weight 4
    weight = Weight.new
    weight.max = 126
    weight.tournament_id = @tournament.id
    weight.save
    create_wrestlers_for_weight(weight, @tournament.schools.sample, 16, 29)

    # Weight 5
    weight = Weight.new
    weight.max = 132
    weight.tournament_id = @tournament.id
    weight.save
    create_wrestlers_for_weight(weight, @tournament.schools.sample, 24, 45)

    # Weight 6
    weight = Weight.new
    weight.max = 138
    weight.tournament_id = @tournament.id
    weight.save
    create_wrestlers_for_weight(weight, @tournament.schools.sample, 8, 69)

    GenerateTournamentMatches.new(@tournament).generate
  end

  def team_point_adjusts_for_wrestler(wrestler_name,points)
    adjust = Teampointadjust.new
    adjust.points = points
    adjust.wrestler_id = get_wrestler_by_name(wrestler_name).id
    adjust.save
  end

  def create_wrestlers_for_weight(weight, school, number_of_wrestlers, naming_start_number)
    naming_number = naming_start_number
    seed = 1
    for number in (1..number_of_wrestlers) do 
      wrestler = Wrestler.new
      wrestler.name = "Test#{naming_number}"
      wrestler.school_id = school.id
      wrestler.weight_id = weight.id
      if (number_of_wrestlers <= 10 and seed <= 4) or (number_of_wrestlers > 10 and seed <= 8) 
        wrestler.original_seed = seed
      end
      wrestler.save
      naming_number = naming_number + 1
      seed = seed + 1
    end
  end

  def end_match(match,winner)
     match.win_type = "Decision"
     match.score = "1-0"
     save_match(match,winner)
  end
  
  def end_match_extra_points(match,winner)
     match.win_type = "Decision"
     match.score = "0-2"
     save_match(match,winner)
  end
  
  def end_match_with_major(match,winner)
     match.win_type = "Major"
     match.score = "8-0"
     save_match(match,winner)
  end
  
  def end_match_with_tech(match,winner)
     match.win_type = "Tech Fall"
     match.score = "15-0"
     save_match(match,winner)
  end
  
  def end_match_with_pin(match,winner)
     match.win_type = "Pin"
     match.score = "5:00"
     save_match(match,winner)
  end
  
  def end_match_with_quickest_pin(match,winner)
     match.win_type = "Pin"
     match.score = "0:20"
     save_match(match,winner)
  end
  
  def end_match_with_quick_pin(match,winner)
     match.win_type = "Pin"
     match.score = "1:20"
     save_match(match,winner)
  end
  
  def end_match_custom(match,win_type,score,winner)
     match.win_type = win_type
     match.score = score
     save_match(match,winner)
  end
  
  def save_match(match,winner)
    match.finished = 1
    match.winner_id = translate_name_to_id(winner)
    
    match.save!
  end
  
  def translate_name_to_id(wrestler)
    Wrestler.where("name = ? AND weight_id = ?", wrestler, @weight.id).first.id
  end

  def get_wrestler_by_name(name)
  	Wrestler.where("name = ? AND weight_id = ?", name, @weight.id).first    
  end

  def match_wrestler_vs(wrestler1_name,wrestler2_name)
    Match.where("(w1 = ? OR w2 = ?) AND (w1 = ? OR w2 = ?)",translate_name_to_id(wrestler1_name), translate_name_to_id(wrestler1_name), translate_name_to_id(wrestler2_name),translate_name_to_id(wrestler2_name)).first
  end

end

# Add support for controller tests
class ActionController::TestCase
  # Authentication helpers for tests - replaces Devise test helpers
  def sign_in(user)
    # Set the password_digest for the user if it's not already set
    unless user.password_digest.present?
      user.password_digest = BCrypt::Password.create("password")
      user.save(validate: false)
    end
    
    # Set the session for the controller test
    @request.session[:user_id] = user.id
  end
end
