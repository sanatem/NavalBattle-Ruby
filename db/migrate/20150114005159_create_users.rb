#bundle exec rake db:migrate
class CreateUsers < ActiveRecord::Migration
  def change
  	create_table :users do |t|
  		t.string :full_name
  		t.string :username
  		t.string :password
  	end
  end
end
