class CreateShips < ActiveRecord::Migration
  def change
  	create_table :ships do |t|
  		t.boolean :state
  		t.integer :coorX
  		t.integer :coorY
  		t.belongs_to :board, index:true
  	end
  end
end
