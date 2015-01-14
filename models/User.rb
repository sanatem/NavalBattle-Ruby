class User < ActiveRecord::Base
	 validates :username, :password, :full_name, presence: true
	 validates :username, uniqueness: true, allow_blank: false
end