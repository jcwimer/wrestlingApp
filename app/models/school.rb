class School < ApplicationRecord
	belongs_to :tournament
	has_many :wrestlers, dependent: :destroy
	has_many :deductedPoints, class_name: "Teampointadjust", dependent: :destroy
	has_many :delegates, class_name: "SchoolDelegate", dependent: :destroy
	
	validates :name, presence: true
	after_commit :invalidate_cached_views, on: [:create, :update]

	before_destroy :prepare_dependents_for_destroy, prepend: true, unless: :destroyed_by_association

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

	def destroy_with_dependents!
		prepare_dependents_for_destroy
		destroy!
	end

	private

	def invalidate_cached_views
		changes = previous_changes.except("updated_at")
		TournamentCacheInvalidator.school_changed(self, changes) if changes.any?
	end

	def prepare_dependents_for_destroy
		return if @dependents_prepared_for_destroy

		@dependents_prepared_for_destroy = true
		tournament.destroy_all_matches
		wrestlers_to_delete = Wrestler.where(school_id: id)
		Teampointadjust.where(wrestler_id: wrestlers_to_delete.select(:id)).delete_all
		wrestlers_to_delete.delete_all
		wrestlers.reset
	end

	public
	
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
		CalculateSchoolScoreJob.perform_later({ school_id: id, tournament_id: tournament_id })
	end

	def calculate_score_raw(wrestlers: self.wrestlers)
	  newScore = total_points_scored_by_wrestlers(wrestlers) - total_points_deducted
    	self.score = newScore
    	self.save
	end
	
	def total_points_scored_by_wrestlers(wrestlers = self.wrestlers)
		points = 0.0
		wrestlers.each do |w|
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
