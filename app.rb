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
      status 403
      body "<h1>Error 403 FORBIDDEN</h1>"
    end
    
  end
  
  get '/logout' do
    session[:user_id] =session[:board_1_id] =nil
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
    @games=Game.where("user_id=#{@user.id} OR player_2_id=#{@user.id}")
    erb :home
  end
  
  #List all the players.
  get '/players' do
    User.all
  end  

  #Create the game

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

      "Has seleccionado: #{params['board']} y tal jugador: #{params['player']}"
      if params['board'].to_i == 5
        max_ships=7
      elsif params['board'].to_i == 10
        max_ships=15
      else
        max_ships=20
      end

      @board=Board.create(size:params['board'].to_i, max_ships: max_ships,user_id: session[:user_id])
      
      
      @game=Game.create( board_1_id:@board.id, player_2_id:params['player'], user_id: session[:user_id],
                         id_turno:params['player'], started: false , finished: false )
      
      @board.game_id=@game.id
      @board.save

      @user=User.find(session[:user_id])

     erb "game/board".to_sym

  end  

  #This update the database with ships

  put '/players/:id/games/:id_game' do

    @board=Board.find_by(game_id:params[:id_game],user_id:params[:id])

    if @board.ships.size < @board.max_ships

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

  #Start a game
  post '/players/:id/games/:id_game' do

    game=Game.find(params[:id_game])
    if !game.board_2_id.nil?
      game.started=true
      game.save
    end

    redirect to :home

  end 

  #2nd player join the game
  get '/players/:id/games/:id_game' do

    @game=Game.find(params[:id_game])
    
    if !@game.started
        
      board_1=Board.find(@game.board_1_id)

      @user=User.find(session[:user_id])
      
      @board=Board.create(size:board_1.size, max_ships:board_1.max_ships ,user_id: @user.id,game_id:@game.id)
      
      @game.board_2_id=@board.id
      @game.save #This saves the 2nd player board
      
      erb "game/board".to_sym
    else
    #Reanuda partida
      #Hallar el player que soy.
      #@board_1=Board.find(game_id:params[:id_game],user_id:params[:id])
      #@board_2=Board.find(game_id:params[:id_game],@game.player_2_id:params[:id])
      erb "game/the_game".to_sym
    end

  end  

end

