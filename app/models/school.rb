class School < ActiveRecord::Base
	belongs_to :tournament
	has_many :wrestlers, dependent: :destroy

	#calculate score here
	def score
		@score = 0
		self.wrestlers.each do |wrestler|
			@match_wins = Match.where(winner_id: wrestler.id)
			@match_wins.each do |m|
				@score = @score + 2
				if m.win_type == "Major"
					@score = @score + 1
				elsif m.win_type == "Tech Fall"
					@score = @score + 1.5
				elsif m.win_type == "Pin"
					@score = @score + 2
				elsif m.win_type == "Forfeit"
					@score = @score + 2
				elsif m.win_type == "Injury Default"
					@score = @score + 2
				elsif m.win_type == "Default"
					@score = @score + 2
				end
			end
		end
		self.score = @score
	end
end
