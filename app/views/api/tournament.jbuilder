
json.cache! ["api_tournament", @tournament] do 
    json.content(@tournament)
    json.(@tournament, :id, :name, :address, :director, :director_email, :tournament_type, :created_at, :updated_at)
    
    json.schools @tournament.schools do |school|
      json.name school.name
      json.score school.score
    end
    
    json.weights @tournament.weights do |weight|
      json.id weight.id
      json.max weight.max
      json.bracket_size weight.bracket_size
      json.wrestlers weight.wrestlers do |wrestler|
        json.id wrestler.id
        json.name wrestler.name
        json.school wrestler.school.name
        json.original_seed wrestler.original_seed
        json.criteria wrestler.criteria
        json.extra wrestler.extra
        json.seasonWinPercentage wrestler.seasonWinPercentage
        json.season_win wrestler.season_win
        json.season_loss wrestler.season_loss
      end
    end
    
    json.mats @tournament.mats do |mat|
      json.name mat.name
      json.unfinishedMatches mat.unfinishedMatches do |match|
        json.w1 = match.w1
        json.w2 = match.w2
        json.bout_number match.bout_number
        json.w1_name match.w1_name
        json.w2_name match.w2_name
      end
    end
    
    json.unassignedMatches @tournament.matches.select{|m| m.mat_id == nil}.sort_by{|m| m.bout_number}[0...9] do |match|
        json.bout_number match.bout_number
        json.w1_name match.w1_name
        json.w2_name match.w2_name
        json.weightClass match.weight.max
        json.round match.round
        json.w1 = match.w1
        json.w2 = match.w2
    end
    
    json.matches @tournament.matches do |match|
        json.bout_number match.bout_number
        json.w1_name match.w1_name
        json.w2_name match.w2_name
        json.weightClass match.weight.max
        json.round match.round
        json.w1 = match.w1
        json.w2 = match.w2
    end
end
