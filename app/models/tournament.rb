class Tournament < ActiveRecord::Base

  include GeneratesLoserNames
  include GeneratesTournamentMatches
	belongs_to :user
	has_many :schools, dependent: :destroy
	has_many :weights, dependent: :destroy
	has_many :mats, dependent: :destroy
	has_many :wrestlers, through: :weights
	has_many :matches, dependent: :destroy
	has_many :delegates, class_name: "TournamentDelegate"

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
			until matsToAssign.sort_by{|m| m.id}.last.matches.count == 4
				matsToAssign.sort_by{|m| m.id}.each do |m|
					m.assignNextMatch	
				end
			end	
		end
	end
	
	def resetMats
		matchesToReset = matches.select{|m| m.mat_id != nil}
		# matchesToReset.update_all( {:mat_id => nil } )
		matchesToReset.each do |m|
			m.mat_id = nil
			m.save
		end
	end
	
	def pointAdjustments
	  point_adjustments = []
      self.schools.each do |s|
        s.deductedPoints.each do |d|
          point_adjustments << d
        end
      end
      self.wrestlers.each do |w|
        w.deductedPoints.each do |d|
          point_adjustments << d
        end
      end
      point_adjustments
    end
    
    def removeSchoolDelegations
	    self.schools.each do |s|
	      s.delegates.each do |d|
	        d.destroy
	      end
	    end
  	end
  	
  	def poolToBracketWeightsWithTooManyWrestlers
  		if self.tournament_type == "Pool to bracket"
  			weightsWithTooManyWrestlers = weights.select{|w| w.wrestlers.size > 16}
  			if weightsWithTooManyWrestlers.size < 1
  				return nil
  			else
  				return weightsWithTooManyWrestlers
  			end
  		else
  			nil
  		end
  	end
  	
  	def tournamentMatchGenerationError
  		errorString = "There is a tournament error."
  		if poolToBracketWeightsWithTooManyWrestlers != nil
  			errorString = errorString + " The following weights have too many wrestlers "
  			poolToBracketWeightsWithTooManyWrestlers.each do |w|
  				errorString = errorString + "#{w.max} "
  			end
  			return errorString
  		else
  			nil
  		end
  	end
  	
  	def swapWrestlers(wrestler1_id,wrestler2_id)
	    w1 = Wrestler.find(wrestler1_id)
	    w2 = Wrestler.find(wrestler2_id)
	    
	    #placeholder guy
 	    w3 = Wrestler.new
 	    w3.name = w1.name
 	    w3.school_id = w1.school_id
 	    w3.weight_id = w1.weight_id
 	    w3.season_win = w1.season_win
 	    w3.season_loss = w1.season_loss
 	    w3.criteria = w1.criteria
 	    w3.original_seed = w1.original_seed
 	    w3.seed = w1.seed
 
  	    
 	    #Swap wrestler 1 and wrestler 2
 	    w1.name = w2.name
 	    w1.school_id = w2.school_id
 	    w1.weight_id = w2.weight_id
 	    w1.season_win = w2.season_win
 	    w1.season_loss = w2.season_loss
 	    w1.criteria = w2.criteria
 	    w1.original_seed = w2.original_seed
 	    w1.seed = w2.seed

  	    
 	    w2.name = w3.name
 	    w2.school_id = w3.school_id
 	    w2.weight_id = w3.weight_id
 	    w2.season_win = w3.season_win
 	    w2.season_loss = w3.season_loss
 	    w2.criteria = w3.criteria
 	    w2.original_seed = w3.original_seed
 	    w2.seed = w3.seed

  	    
  	    w1.save
  	    w2.save
	end
end
