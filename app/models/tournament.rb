class Tournament < ActiveRecord::Base

  include GeneratesLoserNames
  include GeneratesTournamentMatches

	has_many :schools, dependent: :destroy
	has_many :weights, dependent: :destroy
	has_many :mats, dependent: :destroy
	has_many :wrestlers, through: :weights
	has_many :matches, dependent: :destroy

	def tournament_types
		["Pool to bracket"]
	end

  def createCustomWeights(value)
		weights.destroy_all
		if value == 'hs'
			Weight::HS_WEIGHT_CLASSES.each do |w|
				weights.create(max: w)
			end
		else
			raise "Unspecified behavior"
		end
	end

	def upcomingMatches
			matches
	end

	def destroyAllMatches
		matches.destroy_all
	end

	def matchesByRound(round)
		matches.joins(:weight).where(round: round).order("weights.max")
	end

	def assignBouts
		bout_counts = Hash.new(0)
		matches.each do |m|
			m.bout_number = m.round * 1000 + bout_counts[m.round]
			bout_counts[m.round] += 1
			m.save!
		end
	end

end
