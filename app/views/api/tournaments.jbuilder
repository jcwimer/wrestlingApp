json.array!(@tournaments) do |tournament|
  json.extract! tournament, :id, :name, :address, :director, :director_email
end