class CreateBoards < ActiveRecord::Migration
  def up
  	create_table :boards do |t| 
  		t.integer :size
  		t.integer :max_ships
  		t.belongs_to :user, index: true
  	end


  end

  def down
  	drop_table :boards
  end	
end
