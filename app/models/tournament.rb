class Tournament < ActiveRecord::Base

  include GeneratesLoserNames
  include GeneratesTournamentMatches
	belongs_to :user
	has_many :schools, dependent: :destroy
	has_many :weights, dependent: :destroy
	has_many :mats, dependent: :destroy
	has_many :wrestlers, through: :weights
	has_many :matches, dependent: :destroy

	validates :date, :name, :tournament_type, :address, :director, :director_email , presence: true

	def self.search(search)
	  where("date LIKE ? or name LIKE ?", "%#{search}%", "%#{search}%")
	end

	def daysUntil
		time = (Date.today - self.date).to_i
		if time < 0
			time = time * -1
		end
		time
	end

	def resetSchoolScores
		schools.update_all("score = 0.0")
	end

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
	
	def assignFirstMatchesToMats
		assignMats(mats)
	end
	
	def totalRounds
		self.matches.sort_by{|m| m.round}.last.round	
	end
	
	def assignMats(matsToAssign)
		if matsToAssign.count > 0
			until matsToAssign.sort_by{|m| m.id}.last.unfinishedMatches.count == 4
				matsToAssign.sort_by{|m| m.id}.each do |m|
					m.assignNextMatch	
				end
			end	
		end
	end
	
	def resetMats
		matchesToReset = matches.select{|m| m.finished != 1 && m.mat_id != nil}
		# matchesToReset.update_all( {:mat_id => nil } )
		matchesToReset.each do |m|
			m.mat_id = nil
			m.save
		end
	end
end
