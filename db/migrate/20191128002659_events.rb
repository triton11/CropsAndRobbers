class Events < ActiveRecord::Migration
  def change
  	create_table :events do |t|
      t.string :event_type
      t.timestamp :time_start
      t.timestamp :time_end
      t.string :player_affected
      t.belongs_to :player, index: true

      t.timestamps null: false
    end
  end
end
