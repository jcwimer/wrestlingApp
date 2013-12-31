json.array!(@weights) do |weight|
  json.extract! weight, :id, :max
  json.url weight_url(weight, format: :json)
end
