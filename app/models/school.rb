class School < ActiveRecord::Base
	belongs_to :tournament
	has_many :wrestlers, dependent: :destroy

	#calculate score here
	#def score
	#	@score = 0
	#	self.wrestlers.each do |w|
	#		@score = @score + w.season_win * 2
	#	end
	#	self.score = @score
	#end
end
