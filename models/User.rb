class User < ActiveRecord::Base
	 validates :username, :password, :full_name, presence: true
	 validates :username, uniqueness: true, allow_blank: false
	 has_many :games
	 has_many :boards

	 def self.login user,pass
	 	find_by(username: user,password:pass)
	 	
	 end
end