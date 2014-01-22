json.array!(@tournaments) do |tournament|
  json.extract! tournament, :id, :name, :address, :director, :director_email
  json.url tournament_url(tournament, format: :json)
end
