class CreateRooms < ActiveRecord::Migration
  def change
    create_table :rooms do |t|
      t.string :code
      t.string :leader
      t.integer :robber_count
      t.integer :farmer_count
      t.integer :investigator_count
      t.integer :donator_count

      t.integer :round
      t.integer :number_of_rounds
      t.string :participants
      t.integer :round_end
      t.integer :time_per_round

      t.timestamps null: false
    end
  end
end
