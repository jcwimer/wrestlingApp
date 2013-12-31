json.array!(@wrestlers) do |wrestler|
  json.extract! wrestler, :id, :name, :school_id, :weight_id, :seed, :original_seed
  json.url wrestler_url(wrestler, format: :json)
end
