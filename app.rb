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
  #For production: set :database, YAML.load(ERB.new(File.read(File.join("config","database.yml"))).result)
  
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
        session[:user_id]=@user.id
        redirect to :home
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

      @board=Board.create(size:params['board'].to_i, max_ships: max_ships,user_id: session[:user_id],alive_ships:max_ships)
      
      
      @game=Game.create( board_1_id:@board.id, player_2_id:params['player'].to_i, user_id: session[:user_id],
                         id_turno:params['player'].to_i, started: false , finished: false )
      
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
    require_logged_in

    @game=Game.find(params[:id_game])
    @user=User.find(session[:user_id])

    if !@game.started and @game.user_id != @user.id and !@game.finished
        
      board_1=Board.find(@game.board_1_id)
      
      @board=Board.create(size:board_1.size, max_ships:board_1.max_ships ,user_id: @user.id,game_id:@game.id,alive_ships:board_1.max_ships)
      
      @game.board_2_id=@board.id
      @game.save #This saves the 2nd player board
      
      erb "game/board".to_sym
    elsif !@game.started and @game.user_id == @user.id and !@game.finished
      "EL JUEGO NO HA COMENZADO TODAVÍA.."
      
    elsif @game.started and !@game.finished
    #Reanuda partida
      #Hallar el player que soy.
       id1=@game.user_id
       id2=@game.player_2_id
      if(session[:user_id] == id1)
        #i am the player 1
        @board_1=Board.find_by(game_id:params[:id_game],user_id:id1)
        @board_2=Board.find_by(game_id:params[:id_game],user_id:id2)
        
      else #I am the player 2
        @board_1=Board.find_by(game_id:params[:id_game],user_id:id2)
        @board_2=Board.find_by(game_id:params[:id_game],user_id:id1)

      end
      
      @hundidos=Ship.where(state:false,board_id:@board_2.id)

      erb "game/the_game".to_sym
    
    elsif @game.finished
        ships=Board.find_by(user_id:session[:user_id],game_id:@game.id).alive_ships
      if ships > 0
        "HAS GANADO ! ! ! "
      else
        "GAME OVER :( "
      end

    end


  end 

  #Make your move boy!
  post '/players/:id/games/:id_game/move' do
    require_logged_in

    attack=params[:attack].split' - ' #This separate the coordenades
    @game=Game.find(params[:id_game])
    if(@game.id_turno == session[:user_id] and !@game.finished) #It's my turn
      @board=Board.find(params[:attacked_board])

      play=Play.create(coorX:attack[0].to_i,coorY:attack[1].to_i,valid_play:true,user_id:session[:user_id],board_id:@board.id)
       
       #Control de turnos
       player_1=@game.user_id
       player_2=@game.player_2_id
       if(@game.id_turno==player_1)
          @game.id_turno=player_2
       else
          @game.id_turno=player_1
       end
       @game.save

       #Control del juego
       #Traer el barco hundido o no
       ship=Ship.find_by(coorX:play.coorX,coorY:play.coorY,board_id:play.board_id)
       if !ship.nil? and ship.state!= false
        #Lo hunde, it hurts :(
         ship.state=false
         ship.save
         #Descontamos el total de barcos vivos
         board=Board.find(play.board_id)
         board.alive_ships=board.alive_ships-1
         board.save
         if board.alive_ships==0
           @game.finished=true
           @game.started=false
           @game.save
         end
       end
      
      redirect to :home
    else
      status 403
      body "<h1>Error 403 FORBIDDEN</h1>"
    end
    
  
  end


end

