class Wrestler < ActiveRecord::Base
	belongs_to :school, touch: true
	belongs_to :weight, touch: true
	has_one :tournament, through: :weight
	has_many :matches, through: :weight
	has_many :deductedPoints, class_name: "Teampointadjust"
	attr_accessor :poolAdvancePoints, :originalId, :swapId
	
	validates :name, :weight_id, :school_id, presence: true

	before_destroy do 
		self.tournament.destroy_all_matches
	end

	before_create do
		# self.tournament.destroy_all_matches
	end
		

	def last_finished_match
		all_matches.select{|m| m.finished == 1}.sort_by{|m| m.bout_number}.last
	end

	def total_team_points
		CalculateWrestlerTeamScore.new(self).totalScore
	end
	
	def team_points_earned
		CalculateWrestlerTeamScore.new(self).earnedPoints
	end
	
	def placement_points
		CalculateWrestlerTeamScore.new(self).placement_points	
	end

	def total_points_deducted
		CalculateWrestlerTeamScore.new(self).deductedPoints
	end

	def total_pool_points_for_pool_order
      CalculateWrestlerTeamScore.new(self).poolPoints + CalculateWrestlerTeamScore.new(self).bonusWinPoints
	end

	def unfinished_pool_matches
      unfinished_matches.select{|match| match.finished != 1}
	end
	
	def next_match
		unfinished_matches.first
	end
	
	def next_match_position_number
		pos = last_match.bracket_position_number
		return (pos/2.0)	
	end
	
	def last_match
		finished_matches.sort_by{|m| m.round}.reverse.first
	end
	
	def winner_of_last_match?
		if last_match.winner_id == self.id
			return true
		else 
			return false
		end
	end
	
	def next_match_bout_number
		if next_match
			next_match.bout_number
		else
			""
		end
	end
	
	def next_match_mat_name
		if next_match
			next_match.mat_assigned
		else
			""
		end
	end

	def unfinished_matches
		all_matches.select{|m| m.finished != 1}.sort_by{|m| m.bout_number}
	end

	def result_by_bout(bout)
	   bout_match = all_matches.select{|m| m.bout_number == bout and m.finished == 1}
	   if bout_match.size == 0
 		return ""
	   end
	   if bout_match.first.winner_id == self.id
		return "W #{bout_match.first.bracket_score_string}"
	   end
	   if bout_match.first.winner_id != self.id
		return "L #{bout_match.first.bracket_score_string}"
	   end
	end

	def match_against(opponent)
		all_matches.select{|m| m.w1 == opponent.id or m.w2 == opponent.id}
	end

	def is_wrestling_this_round(matchRound)
		if all_matches.blank?
			return false
		else
			return true
		end
	end

	def bout_by_round(round)
		round_match = all_matches.select{|m| m.round == round}.first
		if round_match.blank?
			return "BYE"
		else
			return round_match.bout_number
		end
	end

	def all_matches
		return matches.select{|m| m.w1 == self.id or m.w2 == self.id}
	end
       
	def pool_matches
		all_weight_pool_matches = all_matches.select{|m| m.bracket_position == "Pool"}
		all_weight_pool_matches.select{|m| m.pool_number == self.pool}
	end

	def has_a_pool_bye
		if weight.pool_rounds(matches) > pool_matches.size
			return true
		else
			return false
		end
	end
	
	def championship_advancement_wins
		matches_won.select{|m| (m.bracket_position == "Quarter" or m.bracket_position == "Semis" or m.bracket_position == "Bracket") and m.win_type != "BYE"}
	end
	
	def consolation_advancement_wins
		matches_won.select{|m| (m.bracket_position == "Conso Semis" or m.bracket_position == "Conso" or m.bracket_position == "Conso Quarter") and m.win_type != "BYE"}
	end
	
	def finished_matches
		all_matches.select{|m| m.finished == 1}
	end

	def finished_bracket_matches
		finished_matches.select{|m| m.bracket_position != "Pool"}
	end	

	def finished_pool_matches
		finished_matches.select{|m| m.bracket_position == "Pool"}
	end
	
	def matches_won
		all_matches.select{|m| m.winner_id == self.id}	
	end
	
	def pool_wins
		matches_won.select{|m| m.bracket_position == "Pool" and m.win_type != "BYE"}
	end
	
	def pin_wins
		matches_won.select{|m| m.win_type == "Pin" ||  m.win_type == "Forfeit" ||  m.win_type == "Injury Default" ||  m.win_type == "Default" ||  m.win_type == "DQ"}
	end
	
	def tech_wins
		matches_won.select{|m| m.win_type == "Tech Fall" }
	end
	
	def major_wins
		matches_won.select{|m| m.win_type == "Major" }
	end
	
	def decision_wins
		matches_won.select{|m| m.win_type == "Decision" }
	end
	
	def decision_points_scored
		points_scored = 0
		decision_wins.each do |m|
			score_of_match = m.score.delete(" ")
			score_one = score_of_match.partition('-').first.to_i
			score_two = score_of_match.partition('-').last.to_i
			if score_one > score_two
				points_scored = points_scored + score_one
			elsif score_two > score_one
				points_scored = points_scored + score_two
			end
		end
		points_scored
	end
	
	def fastest_pin
		pin_wins.sort_by{|m| m.pin_time_in_seconds}.first
	end

	def pin_time
      time = 0
      pin_wins.each do | m |
      	time = time + m.pin_time_in_seconds
      end
      time
	end
	
	def season_win_percentage
		win = self.season_win.to_f
		loss = self.season_loss.to_f
		if win > 0 and loss != nil
			match_total = win + loss
			percentage_dec = win / match_total
			percentage = percentage_dec * 100
			return percentage.to_i
		elsif self.season_win == 0
			return 0
		elsif self.season_win == nil or self.season_loss == nil
			return 0
		end
	end

end
