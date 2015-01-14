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
  	erb :login
  end

  post '/auth/login' do
   	#User.new(params['user']['username'],params['user']['password'])
  end

  get '/users' do
  	User.create(username:"forrochan")
  end

  get '/register' do
  	"Registro de usuario"
  end
end

