task :finish_seed_tournaments => :environment do
  finish_tournament(tournament_id)
    @tournament = Tournament.where(:id => tournament_id).includes(:schools,:weights,:mats,:matches,:user,:wrestlers).first
    GenerateTournamentMatches.new(@tournament).generate
    (1..@tournament.reload.total_rounds).each do |round|
    	@tournament.reload.matches_by_round(round).select{|m| m.finished != 1}.each do |match|
        match.reload
        if match.wrestler1.bracket_line < match.wrestler2.bracket_line and match.w1
          match.winner_id = match.w1
        elsif match.w2
          match.winner_id = match.w2
        end
        if match.winner_id
          match.finished = 1
          match.win_type = "Decision"
          match.score = "2-1"
          match.save
        end
      end
    end

  finish_tournament(200)
  finish_tournament(201)
  finish_tournament(202)
  finish_tournament(203)
  finish_tournament(204)
  
end