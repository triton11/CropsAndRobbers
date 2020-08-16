class CreateRooms < ActiveRecord::Migration
  def change
    create_table :rooms do |t|
      t.string :code
      t.string :leader
      t.integer :thief_count
      t.integer :farmer_count
      t.integer :investigator_count

      t.integer :round
      t.integer :number_of_rounds
      t.string :participants
      t.integer :round_end

      t.timestamps null: false
    end
  end
end
