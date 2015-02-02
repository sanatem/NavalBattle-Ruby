class Board < ActiveRecord::Base
	has_many :ships
	has_many :plays

end
