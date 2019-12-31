class CreatePlayers < ActiveRecord::Migration
  def change
    create_table :players do |t|
      t.string :name
      t.string :role
      t.string :visiting
      t.string :activity

      t.integer :score
      t.integer :lives
      t.string :last_round_notice

      #Remove busy_until
      # t.integer :busy_until
      t.integer :round
      t.belongs_to :room, index: true

      t.timestamps null: false
    end
  end
end
