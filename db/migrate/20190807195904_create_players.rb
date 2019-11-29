class CreatePlayers < ActiveRecord::Migration
  def change
    create_table :players do |t|
      t.string :name
      t.string :role
      t.integer :score
      t.integer :lives
      t.string :visiting
      t.timestamp :busy_until
      t.belongs_to :room, index: true

      t.timestamps null: false
    end
  end
end
