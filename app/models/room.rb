class Room < ActiveRecord::Base
  has_many :players
end
