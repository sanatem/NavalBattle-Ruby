class Board < ActiveRecord::Base
	validates :size,:max_ships,:alive_ships, presence:true

	has_many :ships
	has_many :plays
	validates :size,length: { in: 0..15 }
	
	validates :max_ships,length: { in: 0..20 }

	#Board sizes and max ships by size
	BOARD_SIZES={5=>7,10=>15,15=>20}
	temp_ships=[]

	def self.validate_board size
		if BOARD_SIZES.has_key?size
			BOARD_SIZES[size]
		else
			nil		
		end	
	end
end
