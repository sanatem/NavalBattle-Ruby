class CreateGames < ActiveRecord::Migration
  def up
  	create_table :games do |t|
  		t.belongs_to :user, index: true
  		t.integer :board_1_id
      t.integer :board_2_id
  		t.integer :player_2_id
      t.boolean :started
      t.boolean :finished
      t.integer :id_turno
  	end	
  end

  def down
  	drop_table :games
  end	

end

