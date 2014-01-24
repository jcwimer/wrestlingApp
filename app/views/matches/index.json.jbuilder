json.array!(@matches) do |match|
  json.extract! match, :id, :r_id, :g_id, :g_stat, :r_stat, :winner_id, :win_type, :score
  json.url match_url(match, format: :json)
end
