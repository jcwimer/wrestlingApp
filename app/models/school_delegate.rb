class SchoolDelegate < ActiveRecord::Base
    belongs_to :school
    belongs_to :user
end
