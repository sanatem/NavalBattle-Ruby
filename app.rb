require 'bundler'

ENV['RACK_ENV'] ||= 'development'
Bundler.require :default, ENV['RACK_ENV'].to_sym

Dir['./models/**/*.rb'].each {|f| require f }

class Application < Sinatra::Base

  #Configuration
  register Sinatra::ActiveRecordExtension

  configure :production, :development do
    enable :logging
  end

  
  set :database, YAML.load_file('config/database.yml')[ENV['RACK_ENV']]

  
  #Extensions from sinatra 
  enable :sessions

  #Methods and helpers

  def require_logged_in
    redirect('/') unless is_authenticated?
  end
 
  def is_authenticated?
    return !!session[:user_id]
  end


  #Routes

  get '/' do
  	erb :index
  end

  post '/auth/login' do
  	username=params['user']['username']
  	password=params['user']['password']
  	finded_user=User.find_by(username: username,password:password)
  	if finded_user
      session[:user_id]=finded_user.id
  		redirect to :home
  	else
  		"Username or Password are incorrect"
  	end

  end
  
  get '/logout' do
    session[:user_id] = nil
    redirect to '/'
  end
  
  #Register route
  post '/register' do
  	username=params['user']['username']
  	password=params['user']['password']
  	full_name=params['user']['name']

  	created_user=User.create(full_name: full_name,username: username,password: password)

  	if created_user.valid?
  		redirect to :home
  	else
  		redirect to '/'
  	end
  end #End register

  #Home route
  get '/home'  do 
    require_logged_in
    erb :home
  end
  


end

