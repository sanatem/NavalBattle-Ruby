require 'bundler'
require 'thin'
require 'webrick'
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
    else
      status 403
      body "<h1>Error 403 FORBIDDEN</h1>"
    end
  end
  
  get '/logout' do
    session[:user_id] = nil
    redirect to '/'
  end
  
  #Register route

  post '/players' do
  	username=params['user']['username']
  	password=params['user']['password']
  	full_name=params['user']['name']
    m=username.match(/^[a-zA-Z]+/)
    if m.nil? then
      status 400
      body "<h1>Bad request</h1>"
    else
      p m
      @user=User.create(full_name: full_name,username: username,password: password)
      if @user.valid?
  		#status 201 => Adjust this for production, agh and an error body
      #session[:user_id]=created_user.id
      #redirect to :home => This works but the status code dissappear.
      status 201
      erb :home
    else
      status 409
      body "Error 409 Conflict"
    end
  end
  end #End register

  #Home route
  get '/home' do 
    require_logged_in
    @user=User.find(session[:user_id])
    erb :home
  end
  
  #List all the players.
  get '/players' do
    User.all
  end  

  get '/players/games/create' do
    users=User.where.not(id: session[:user_id] )
    @options=[]
    users.each do |user|
      @options << "<option value= #{user.id}> #{user.username}</option>" 
    end
    p users
    erb "game/create".to_sym
  end

  post '/players/games' do
<<<<<<< HEAD
      "Has seleccionado: #{params['board']} y tal jugador: #{params['player']}"
      if params['board'].to_i == 5
        max_ships=7
      elsif params['board'].to_i == 10
        max_ships=15
      else
        max_ships=20
      end

      @board=Board.create(size:params['board'].to_i, max_ships: max_ships,user_id: session[:user_id])
      session[:board_1_id]=@board.id
      @game=Game.create( board_id:@board.id, player_2_id:params['player'], user_id: session[:user_id])
      
      @user=User.find(session[:user_id])

     erb "game/board".to_sym
  end  

  #This update the database with
  put '/players/:id/games/:id_game' do
  
    @board=Board.find(session[:board_1_id])
    
    if @board.ships.size <= @board.max_ships

      uid=params[:id]
      gameid=params[:id_game]
      coor_x= params[:coor_x]
      coor_y= params[:coor_y]
      @ship=Ship.new(state:true, coorX:coor_x, coorY:coor_y)
      @board.ships << @ship #This stores the ship into the database and the board.
      "Agregado Barco (#{@ship.coorX},#{@ship.coorY})"
    else
      "NO HAY MAS QUE AGREGAR ACA"
    end#End if
  
  end

  post '/players/:id/games/:id_game' do

    "Juego iniciado.."

  end  

end

