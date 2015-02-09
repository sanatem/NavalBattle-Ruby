require 'bundler'

ENV['RACK_ENV'] ||= 'development'
Bundler.require :default, ENV['RACK_ENV'].to_sym

Dir['./models/**/*.rb'].each {|f| require f }

class Application < Sinatra::Base

  #Configuration
  register Sinatra::ActiveRecordExtension

  configure :production, :development, :test do
    enable :logging
  end

  
  set :database, YAML.load_file('config/database.yml')[ENV['RACK_ENV']]
  #For production: 

  #set :database, YAML.load(ERB.new(File.read(File.join("config","database.yml"))).result)
  
  #Extensions from sinatra 
  enable :sessions

  #Methods and helpers

  temp_ships=[]

  def require_logged_in
    redirect('/') unless is_authenticated?
  end
  
  def is_authenticated?
    return !!session[:user_id]
  end

  def load_game id_game,id_user
     #Reanuda partida
      #Hallar el player que soy.
       @user=User.find(id_user)
       @game=Game.find(id_game)
       id1=@game.user_id
       id2=@game.player_2_id
      if(session[:user_id] == id1)
        #i am the player 1
        @board_1=Board.find_by(game_id:id_game,user_id:id1)
        @board_2=Board.find_by(game_id:id_game,user_id:id2)
        
      else #I am the player 2
        @board_1=Board.find_by(game_id:id_game,user_id:id2)
        @board_2=Board.find_by(game_id:id_game,user_id:id1)
      end
      @hundidos=Ship.where(state:false,board_id:@board_2.id)

      erb "game/the_game".to_sym
  end




  #Routes

  get '/' do
  	erb :index
  end

  post '/auth/login' do
  	username=params['user']['username']
  	password=params['user']['password']
  	finded_user=User.login(username,password)
  	if finded_user
      session[:user_id]=finded_user.id
      redirect to :home
    else
      status 403
      body "<h1>Error 403 FORBIDDEN</h1>"
    end
    
  end
  
  get '/logout' do
    status 200
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
      @user=User.create(full_name: full_name,username: username,password: password)
      if @user.valid?
        session[:user_id]=@user.id
        status 201
        "<a href='/home'>Go to home</a>"
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
    @started=@games.select{|g| g.finished==false}
    @finished=@games.select{|g| g.finished==true}
    erb :home
  end
  
  #List all the players.
  get '/players' do
    @players=User.all
    erb "game/players".to_sym
  end

  #List all the games
  get '/players/:id/games' do
      @games=Game.where("user_id=#{params[:id].to_i} OR player_2_id=#{params[:id].to_i}")
      @player=User.find(params[:id].to_i)
      erb "game/games".to_sym
  end  

  #Start creating the game

  get '/players/games/create' do
    temp_ships=[]
    require_logged_in
    users=User.where.not(id: session[:user_id] )
    @options=[]
    users.each do |user|
      @options << "<option value= #{user.id}> #{user.username}</option>" 
    end
    @id=session[:user_id]
    erb "game/create".to_sym
  end

  #Create a Game
  post '/players/:id/games' do
    require_logged_in

    board_size=params['board'].to_i
    max_ships=Board.validate_board (board_size)

    if max_ships.nil? #Invalid size of board
      status 400
      "Error 404 Bad Request" 
      halt
    end

      @board=Board.create(size:params['board'].to_i, max_ships: max_ships,user_id: session[:user_id],alive_ships:max_ships)
      
      
      @game=Game.create( board_1_id:@board.id, player_2_id:params['player'].to_i, user_id: session[:user_id],
                         id_turno:params['player'].to_i, started: false , finished: false )
      
      @board.game_id=@game.id
      @board.save

      @user=User.find(session[:user_id])

      if @game.valid?
        status 201
        erb "game/board".to_sym
      else
        status 400
        "Error 404 Bad Request"   
      end
  end  

  #This update the database with ships
  
  
  put '/players/:id/games/:id_game' do
    require_logged_in
    @game=Game.find(params[:id_game])
    
    if(!@game.started)
      @board=Board.find_by(game_id:params[:id_game],user_id:params[:id])
      if temp_ships.size < @board.max_ships
        gameid=params[:id_game]
        @ship=@board.add_ship(temp_ships,params[:coor_x],params[:coor_y])        
        status 200
      else
        status 400
        body "Bad request"
        halt
      end
    else
      "The game has started you can't add more ships . . ."
    end#End if

  end

  #Start a game
  post '/players/:id/games/:id_game' do

    game=Game.find(params[:id_game])
    #validations

    if !game.board_2_id.nil?
      game.started=true
      game.save
    end

    redirect to :home

  end 

  #2nd player join the game
  get '/players/:id/games/:id_game' do
    require_logged_in

    @game=Game.find(params[:id_game])
    @user=User.find(session[:user_id])

    if !@game.started and @game.user_id != @user.id and !@game.finished
        
      @board=@game.add_2nd_player(@user.id)
      
      erb "game/board".to_sym

    elsif !@game.started and @game.user_id == @user.id and !@game.finished
      "EL JUEGO NO HA COMENZADO TODAVIA.."
      
    elsif @game.started and !@game.finished

      load_game(params[:id_game],params[:id])
      
    elsif @game.finished
      erb Game.decide_win(@game.id,session[:user_id])
    end


  end 

  #Make your move boy!
  post '/players/:id/games/:id_game/move' do
    require_logged_in

    attack=params[:attack].split' - ' #This separate the coordenades
    
    @game=Game.find(params[:id_game])
    
    if(@game.id_turno == session[:user_id] and !@game.finished) #It's my turn
      
      status 201

      @board=Board.find(params[:attacked_board])
      play=Play.create(coorX:attack[0].to_i,coorY:attack[1].to_i,valid_play:true,user_id:session[:user_id],board_id:@board.id)
      
       #Control de turnos
       @game.change_turn
       #Control del juego
       #Traer el barco hundido o no
       @game.make_the_play(play)
      
      if(!@game.finished)
        load_game(params[:id_game],params[:id])
      else
        erb Game.decide_win(@game.id,session[:user_id])
      end  
      
    elsif @game.id_turno != session[:user_id]
      status 403
      body "<h1>Error 403 FORBIDDEN</h1>"  
    else
      erb Game.decide_win(@game.id,session[:user_id])
    end
  end


end
