class School < ApplicationRecord
	belongs_to :tournament, touch: true
	has_many :wrestlers, dependent: :destroy
	has_many :deductedPoints, class_name: "Teampointadjust", dependent: :destroy
	has_many :delegates, class_name: "SchoolDelegate", dependent: :destroy
	
	validates :name, presence: true

	attr_accessor :baums_text

	before_destroy do 
		self.tournament.destroy_all_matches
	end

	def abbreviation
      name_array = self.name.split(' ')
      if name_array.size > 2
      	# If three words, use first letter of first word, first letter of second, and first two of third
      	return "#{name_array[0].chars.to_a.first}#{name_array[1].chars.to_a.first}#{name_array[2].chars.to_a[0..1].join('').upcase}"
      elsif name_array.size > 1
        # If two words use first letter of first word and first three of the second
      	return "#{name_array[0].chars.to_a.first}#{name_array[1].chars.to_a[0..2].join('').upcase}"
      else
      	# If one word use first four letters
        return "#{name_array[0].chars.to_a[0..3].join('').upcase}"
      end
	end
	
	#calculate score here
	def page_score_string
		if self.score == nil
			return 0.0
		else
			return self.score
		end
	end
	
	def calculate_score
		# Use perform_later which will execute based on centralized adapter config
		CalculateSchoolScoreJob.perform_later(self)
	end

	def calculate_score_raw
      newScore = total_points_scored_by_wrestlers - total_points_deducted
    	self.score = newScore
    	self.save
	end
	
	def total_points_scored_by_wrestlers
		points = 0.0
		self.wrestlers.each do |w|
			points = points + w.total_team_points
		end
		points
	end
	
	def total_points_deducted
		points = 0.0
		deductedPoints.each do |d|
			points = points + d.points
		end
		points
	end
end
