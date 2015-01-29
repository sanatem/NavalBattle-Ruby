class CreateGames < ActiveRecord::Migration
  def up
  	create_table :games do |t|
  		t.belongs_to :user, index: true
  		t.string :board
  		t.integer :player_2_id
  	end	
  end

  def down
  	drop_table :games
  end	

end

