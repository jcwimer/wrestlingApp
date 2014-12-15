# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
if Rails.env.development?
	User.create(email: 'test@test.com', password: 'password', password_confirmation: 'password')
	Tournament.create(id: 200, name: 'test', address: 'some place', director: 'some guy', director_email: 'hismail@email.com')
	School.create(id: 200, name: 'Central Crossing', tournament_id: 200)
	Weight.create(id: 200, max: 132, tournament_id: 200 )
	Wrestler.create(name: 'Guy 1', school_id: 200, weight_id: 200, original_seed: 1, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 2', school_id: 200, weight_id: 200, original_seed: 2, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 3', school_id: 200, weight_id: 200, original_seed: 3, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 4', school_id: 200, weight_id: 200, original_seed: 4, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 5', school_id: 200, weight_id: 200, original_seed: 5, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 6', school_id: 200, weight_id: 200, original_seed: 6, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 7', school_id: 200, weight_id: 200, original_seed: 7, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 8', school_id: 200, weight_id: 200, original_seed: 8, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 9', school_id: 200, weight_id: 200, original_seed: 9, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 10', school_id: 200, weight_id: 200, original_seed: 10, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 11', school_id: 200, weight_id: 200, original_seed: 11, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 12', school_id: 200, weight_id: 200, original_seed: 12, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 13', school_id: 200, weight_id: 200, original_seed: 13, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 14', school_id: 200, weight_id: 200, original_seed: 14, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 15', school_id: 200, weight_id: 200, original_seed: 15, season_win: 0, season_loss: 0, criteria: 'N/A')
	Wrestler.create(name: 'Guy 16', school_id: 200, weight_id: 200, original_seed: 16, season_win: 0, season_loss: 0, criteria: 'N/A')
end


