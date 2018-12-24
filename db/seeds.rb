# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
#if Rails.env.development?
	User.create(id: 1, email: 'test@test.com', password: 'password', password_confirmation: 'password')
	Tournament.create(id: 200, name: 'test', address: 'some place', director: 'some guy', director_email: 'hismail@email.com', tournament_type: 'Pool to bracket', user_id: 1, date: Date.today)
	School.create(id: 200, name: 'Central Crossing', tournament_id: 200)
	School.create(id: 201, name: 'Turd Town', tournament_id: 200)
	School.create(id: 202, name: 'Shit Show', tournament_id: 200)
	School.create(id: 203, name: 'Westland', tournament_id: 200)
	School.create(id: 204, name: 'Grove City', tournament_id: 200)
	School.create(id: 205, name: 'Franklin Heights', tournament_id: 200)
	Weight.create(id: 200, max: 132, tournament_id: 200 )
	Weight.create(id: 201, max: 106, tournament_id: 200 )
	Weight.create(id: 202, max: 113, tournament_id: 200 )
	Weight.create(id: 203, max: 120, tournament_id: 200 )
	Weight.create(id: 204, max: 126, tournament_id: 200 )
	Weight.create(id: 205, max: 138, tournament_id: 200 )
	Mat.create(id: 200, name: "1", tournament_id: 200 )
	Mat.create(id: 201, name: "2", tournament_id: 200 )
	Mat.create(id: 202, name: "3", tournament_id: 200 )
	Mat.create(id: 203, name: "4", tournament_id: 200 )
	Wrestler.create(name: 'Guy 1', school_id: 200, weight_id: 200, original_seed: 1, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 2', school_id: 201, weight_id: 200, original_seed: 2, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 3', school_id: 202, weight_id: 200, original_seed: 3, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 4', school_id: 203, weight_id: 200, original_seed: 4, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 5', school_id: 204, weight_id: 200, original_seed: 5, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 6', school_id: 200, weight_id: 200, original_seed: 6, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 7', school_id: 200, weight_id: 200, original_seed: 7, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 8', school_id: 200, weight_id: 200, original_seed: 8, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 9', school_id: 200, weight_id: 200, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 10', school_id: 200, weight_id: 200, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 11', school_id: 200, weight_id: 200, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 12', school_id: 200, weight_id: 200, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 13', school_id: 200, weight_id: 200, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 14', school_id: 200, weight_id: 200, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 15', school_id: 200, weight_id: 200, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 16', school_id: 200, weight_id: 200, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 17', school_id: 200, weight_id: 201, original_seed: 1, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 18', school_id: 201, weight_id: 201, original_seed: 2, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 19', school_id: 202, weight_id: 201, original_seed: 3, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 20', school_id: 203, weight_id: 201, original_seed: 4, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 21', school_id: 204, weight_id: 201, original_seed: 5, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 22', school_id: 200, weight_id: 201, original_seed: 6, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 23', school_id: 200, weight_id: 201, original_seed: 7, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 24', school_id: 200, weight_id: 201, original_seed: 8, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 25', school_id: 200, weight_id: 201, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 26', school_id: 201, weight_id: 201, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 27', school_id: 202, weight_id: 201, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 30', school_id: 204, weight_id: 202, original_seed: 1, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 31', school_id: 204, weight_id: 202, original_seed: 2, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 32', school_id: 204, weight_id: 202, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 33', school_id: 204, weight_id: 202, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 34', school_id: 204, weight_id: 202, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	
	Wrestler.create(name: 'Guy 35', school_id: 204, weight_id: 203, original_seed: 1, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 36', school_id: 204, weight_id: 203, original_seed: 2, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 37', school_id: 204, weight_id: 203, original_seed: 3, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 38', school_id: 204, weight_id: 203, original_seed: 4, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 39', school_id: 204, weight_id: 203, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 40', school_id: 204, weight_id: 203, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 41', school_id: 204, weight_id: 203, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 42', school_id: 204, weight_id: 203, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 43', school_id: 204, weight_id: 203, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 44', school_id: 204, weight_id: 203, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	
	Wrestler.create(name: 'Guy 45', school_id: 204, weight_id: 204, original_seed: 1, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 46', school_id: 204, weight_id: 204, original_seed: 2, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 47', school_id: 204, weight_id: 204, original_seed: 3, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 48', school_id: 204, weight_id: 204, original_seed: 4, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 49', school_id: 204, weight_id: 204, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 50', school_id: 204, weight_id: 204, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 51', school_id: 204, weight_id: 204, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 52', school_id: 204, weight_id: 204, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	
	Wrestler.create(name: 'Guy 53', school_id: 204, weight_id: 205, original_seed: 1, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 54', school_id: 204, weight_id: 205, original_seed: 2, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 55', school_id: 204, weight_id: 205, original_seed: 3, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 56', school_id: 204, weight_id: 205, original_seed: 4, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 57', school_id: 204, weight_id: 205, original_seed: 5, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 58', school_id: 204, weight_id: 205, original_seed: 6, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 59', school_id: 204, weight_id: 205, original_seed: 7, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 60', school_id: 204, weight_id: 205, original_seed: 8, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 61', school_id: 204, weight_id: 205, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 62', school_id: 204, weight_id: 205, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 63', school_id: 204, weight_id: 205, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 64', school_id: 204, weight_id: 205, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 65', school_id: 204, weight_id: 205, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 66', school_id: 204, weight_id: 205, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 67', school_id: 204, weight_id: 205, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 68', school_id: 204, weight_id: 205, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 69', school_id: 204, weight_id: 205, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 70', school_id: 204, weight_id: 205, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 71', school_id: 204, weight_id: 205, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 72', school_id: 204, weight_id: 205, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 73', school_id: 204, weight_id: 205, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 74', school_id: 204, weight_id: 205, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 75', school_id: 204, weight_id: 205, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 76', school_id: 204, weight_id: 205, original_seed: nil, season_win: 0, season_loss: 0, criteria: 'N/A')
#end




