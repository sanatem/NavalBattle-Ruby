class Board < ActiveRecord::Base

	has_many :ships
	has_many :plays

	validates :size,:max_ships,:alive_ships, presence:true

	validates :size,length: { in: 0..15 }
	
	validates :max_ships,length: { in: 0..20 }
	
	
	#Board sizes and max ships by size
	BOARD_SIZES={5=>7,10=>15,15=>20}

	def self.validate_board size
		if BOARD_SIZES.has_key?size
			BOARD_SIZES[size]
		else
			nil		
		end	
	end

	#Returns a SHip (If it's ok or nil)
	def add_ship(temp_ships,coor_x,coor_y)
		exist=temp_ships.detect{|ship| ship.coorX==coor_x and ship.coorY==coor_y }
        
        if (exist.nil?) 
          @ship=Ship.new(board_id:self.id,state:true, coorX:coor_x, coorY:coor_y)
          temp_ships << @ship #This stores the ship into the database and the board.
          if temp_ships.size == self.max_ships
            self.ships = temp_ships
            self.save
            temp_ships=[]
          end  	
		@ship
		else
			nil
		end	
	end
end
