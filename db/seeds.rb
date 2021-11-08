# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
#if Rails.env.development?
	def create_schools(tournament, number_of_schools)
	  for number in (1..number_of_schools) do 
        school = School.new
        school.name = "School#{number}"
        school.tournament_id = tournament.id
        school.save
      end	
	end
	
	def create_wrestlers_for_weight(weight, tournament, number_of_wrestlers, naming_start_number)
      naming_number = naming_start_number
      for number in (1..number_of_wrestlers) do
        wrestler = Wrestler.new
        wrestler.name = "Wrestler#{naming_number}"
        wrestler.school_id = tournament.schools.select{|s|s.name == "School#{number}"}.first.id
        wrestler.weight_id = weight.id
        wrestler.original_seed = number
        wrestler.save
        naming_number = naming_number + 1
      end
    end

	User.create(id: 1, email: 'test@test.com', password: 'password', password_confirmation: 'password')
	
	# Pool to bracket
	tournament = Tournament.create(id: 200, name: 'Test1', address: 'some place', director: 'some guy', director_email: 'their@email.com', tournament_type: 'Pool to bracket', user_id: 1, date: Date.today)
	create_schools(tournament, 16)
	weight_classes=Weight::HS_WEIGHT_CLASSES.split(",")
	tournament.create_pre_defined_weights(weight_classes)
	wrestler_name_number = 1
	tournament.weights.each do |weight|
	  create_wrestlers_for_weight(weight, tournament, 16, wrestler_name_number)
	  wrestler_name_number += 16
	end
	
	# Modified 16 Man Double Elimination 1-6
	tournament = Tournament.create(id: 201, name: 'Test2', address: 'some place', director: 'some guy', director_email: 'their@email.com', tournament_type: 'Modified 16 Man Double Elimination 1-6', user_id: 1, date: Date.today)
	create_schools(tournament, 16)
	weight_classes=Weight::HS_WEIGHT_CLASSES.split(",")
	tournament.create_pre_defined_weights(weight_classes)
	wrestler_name_number = 1
	tournament.weights.each do |weight|
	  create_wrestlers_for_weight(weight, tournament, 16, wrestler_name_number)
	  wrestler_name_number += 16
	end
	
	# Modified 16 Man Double Elimination 1-8
	tournament = Tournament.create(id: 202, name: 'Test3', address: 'some place', director: 'some guy', director_email: 'their@email.com', tournament_type: 'Modified 16 Man Double Elimination 1-8', user_id: 1, date: Date.today)
	create_schools(tournament, 16)
	weight_classes=Weight::HS_WEIGHT_CLASSES.split(",")
	tournament.create_pre_defined_weights(weight_classes)
	wrestler_name_number = 1
	tournament.weights.each do |weight|
	  create_wrestlers_for_weight(weight, tournament, 16, wrestler_name_number)
	  wrestler_name_number += 16
	end
	
	# Regular Double Elimination 1-6
	tournament = Tournament.create(id: 203, name: 'Test4', address: 'some place', director: 'some guy', director_email: 'their@email.com', tournament_type: 'Regular Double Elimination 1-6', user_id: 1, date: Date.today)
	create_schools(tournament, 16)
	weight_classes=Weight::HS_WEIGHT_CLASSES.split(",")
	tournament.create_pre_defined_weights(weight_classes)
	wrestler_name_number = 1
	tournament.weights.each do |weight|
	  create_wrestlers_for_weight(weight, tournament, 16, wrestler_name_number)
	  wrestler_name_number += 16
	end
	
	# Regular Double Elimination 1-8
	tournament = Tournament.create(id: 204, name: 'Test5', address: 'some place', director: 'some guy', director_email: 'their@email.com', tournament_type: 'Regular Double Elimination 1-8', user_id: 1, date: Date.today)
	create_schools(tournament, 16)
	weight_classes=Weight::HS_WEIGHT_CLASSES.split(",")
	tournament.create_pre_defined_weights(weight_classes)
	wrestler_name_number = 1
	tournament.weights.each do |weight|
	  create_wrestlers_for_weight(weight, tournament, 16, wrestler_name_number)
	  wrestler_name_number += 16
	end
#end






