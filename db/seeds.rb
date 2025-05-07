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
	
	# Set tournament date to a month from today
	future_date = 1.month.from_now.to_date
	
	# Pool to bracket
	tournament = Tournament.create(id: 200, name: 'Pool to bracket', address: 'some place', director: 'some guy', director_email: 'their@email.com', tournament_type: 'Pool to bracket', user_id: 1, date: future_date, is_public: true)
	create_schools(tournament, 24)
	weight_classes=Weight::HS_WEIGHT_CLASSES.split(",")
	tournament.create_pre_defined_weights(weight_classes)
	wrestler_name_number = 1
	tournament.weights.each_with_index do |weight, index|
	  if index == 0
		number_of_wrestlers = 6
	  elsif index == 1
		number_of_wrestlers = 8
	  elsif index == 2
		number_of_wrestlers = 10
	  elsif index == 3
		number_of_wrestlers = 12
	  elsif index == 4
		number_of_wrestlers = 24
	  elsif index == 5
		number_of_wrestlers = 2
	  else
		number_of_wrestlers = 16
	  end
	  
	  create_wrestlers_for_weight(weight, tournament, number_of_wrestlers, wrestler_name_number)
	  wrestler_name_number += number_of_wrestlers
	end
	
	# Modified 16 Man Double Elimination 1-6
	tournament = Tournament.create(id: 201, name: 'Modified 16 Man Double Elimination 1-6', address: 'some place', director: 'some guy', director_email: 'their@email.com', tournament_type: 'Modified 16 Man Double Elimination 1-6', user_id: 1, date: future_date, is_public: true)
	create_schools(tournament, 16)
	weight_classes=Weight::HS_WEIGHT_CLASSES.split(",")
	tournament.create_pre_defined_weights(weight_classes)
	wrestler_name_number = 1
	tournament.weights.each do |weight|
	  create_wrestlers_for_weight(weight, tournament, 16, wrestler_name_number)
	  wrestler_name_number += 16
	end
	
	# Modified 16 Man Double Elimination 1-8
	tournament = Tournament.create(id: 202, name: 'Modified 16 Man Double Elimination 1-8', address: 'some place', director: 'some guy', director_email: 'their@email.com', tournament_type: 'Modified 16 Man Double Elimination 1-8', user_id: 1, date: future_date, is_public: true)
	create_schools(tournament, 16)
	weight_classes=Weight::HS_WEIGHT_CLASSES.split(",")
	tournament.create_pre_defined_weights(weight_classes)
	wrestler_name_number = 1
	tournament.weights.each_with_index do |weight, index|
		if index == 0
		  number_of_wrestlers = 12
		else
		  number_of_wrestlers = 16
		end
		
		create_wrestlers_for_weight(weight, tournament, number_of_wrestlers, wrestler_name_number)
		wrestler_name_number += number_of_wrestlers
	end
	
	# Regular Double Elimination 1-6
	tournament = Tournament.create(id: 203, name: 'Regular Double Elimination 1-6', address: 'some place', director: 'some guy', director_email: 'their@email.com', tournament_type: 'Regular Double Elimination 1-6', user_id: 1, date: future_date, is_public: true)
	create_schools(tournament, 32)
	weight_classes=Weight::HS_WEIGHT_CLASSES.split(",")
	tournament.create_pre_defined_weights(weight_classes)
	wrestler_name_number = 1
	tournament.weights.each_with_index do |weight, index|
		if index == 0
			number_of_wrestlers = 4
		elsif index == 1
			number_of_wrestlers = 8
		elsif index == 2
			number_of_wrestlers = 32
		elsif index == 3
			number_of_wrestlers = 17
		else
			number_of_wrestlers = 16
		end
		
		create_wrestlers_for_weight(weight, tournament, number_of_wrestlers, wrestler_name_number)
		wrestler_name_number += number_of_wrestlers
	end
	
	# Regular Double Elimination 1-8
	tournament = Tournament.create(id: 204, name: 'Regular Double Elimination 1-8', address: 'some place', director: 'some guy', director_email: 'their@email.com', tournament_type: 'Regular Double Elimination 1-8', user_id: 1, date: future_date, is_public: true)
	create_schools(tournament, 32)
	weight_classes=Weight::HS_WEIGHT_CLASSES.split(",")
	tournament.create_pre_defined_weights(weight_classes)
	wrestler_name_number = 1
	tournament.weights.each_with_index do |weight, index|
		if index == 0
		  number_of_wrestlers = 4
		elsif index == 1
		  number_of_wrestlers = 8
		elsif index == 2
			number_of_wrestlers = 32
		elsif index == 3
			number_of_wrestlers = 17
		else
		  number_of_wrestlers = 16
		end
		
		create_wrestlers_for_weight(weight, tournament, number_of_wrestlers, wrestler_name_number)
		wrestler_name_number += number_of_wrestlers
	end
#end






