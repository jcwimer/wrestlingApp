json.array!(@mats) do |mat|
  json.extract! mat, :id, :name, :tournament_id
  json.url mat_url(mat, format: :json)
end
