class Player < ActiveRecord::Base
	belongs_to :room
	has_many :events
end
