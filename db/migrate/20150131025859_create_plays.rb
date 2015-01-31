class CreatePlays < ActiveRecord::Migration
  def change
  	create_table :plays do | t|
	  	t.integer :coorX
	    t.integer :coorY
	    t.integer :user_id
	    t.boolean :valid
	    t.belongs_to :board
	 end
  end
end
