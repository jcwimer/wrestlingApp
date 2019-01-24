class School < ActiveRecord::Base
	belongs_to :tournament, touch: true
	has_many :wrestlers, dependent: :destroy
	has_many :deductedPoints, class_name: "Teampointadjust"
	has_many :delegates, class_name: "SchoolDelegate"
	
	validates :name, presence: true

	attr_accessor :baums_text

	before_destroy do 
		self.tournament.destroy_all_matches
	end

	def abbreviation
      name_array = self.name.split(' ')
      if name_array.size > 1
      	return "#{name_array[0].chars.to_a.first}#{name_array[1].chars.to_a[0..1].join('').upcase}"
      else
        return "#{name_array[0].chars.to_a[0..2].join('').upcase}"
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
    	newScore = total_points_scored_by_wrestlers - total_points_deducted
    	self.score = newScore
    	self.save
   	end
   	if Rails.env.production?
		handle_asynchronously :calculate_score
	end
	
	def total_points_scored_by_wrestlers
		points = 0
		self.wrestlers.each do |w|
			if w.extra != true
				points = points + w.total_team_points
			end
		end
		points
	end
	
	def total_points_deducted
		points = 0
		deductedPoints.each do |d|
			points = points + d.points
		end
		self.wrestlers.each do |w|
			w.deductedPoints.each do |d|
				points = points + d.points
			end
		end
		points
	end
end
