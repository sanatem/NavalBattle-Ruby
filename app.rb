require 'bundler'

ENV['RACK_ENV'] ||= 'development'
Bundler.require :default, ENV['RACK_ENV'].to_sym

Dir['./models/**/*.rb'].each {|f| require f }

class Application < Sinatra::Base

  register Sinatra::ActiveRecordExtension

  configure :production, :development do
    enable :logging
  end

  set :database, YAML.load_file('config/database.yml')[ENV['RACK_ENV']]

  get '/' do
  	erb :index
  end

  post '/auth/login' do
  	username=params['user']['username']
  	password=params['user']['password']
  	finded_user=User.find_by(username: username,password:password)
  	if finded_user
  		"ESTAS LOGUEADO"
  	else
  		"NO EXISTIS PA"
  	end

  end

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

  end
end

