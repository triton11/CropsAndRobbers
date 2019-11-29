class CreateRooms < ActiveRecord::Migration
  def change
    create_table :rooms do |t|
      t.string :code
      t.string :leader
      t.integer :thief_count
      t.integer :farmer_count

      t.timestamps null: false
    end
  end
end
