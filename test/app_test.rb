require 'test_helper'

class RootTest < AppTest
  	include Rack::Test::Methods
  	
  	def setup
  		@user=User.create(username:"my_test",password:"jodida",full_name:"Lindsdey")
      @invalid_user=User.create(username:" ",password:"complicada",full_name:"fullnamealgo")
  		@player_2=User.create(username:"my_juanma",password:"jodida",full_name:"Juanma")
		  @board_1=Board.create(size:5, max_ships: 7,user_id:@user.id,alive_ships:7)
		  @board_2=Board.create(size:5, max_ships: 7,user_id:@player_2.id,alive_ships:7)
  		@game=Game.create( board_1_id:@board_1.id, player_2_id:@player_2.id, user_id: @user.id,
                         id_turno:@player_2.id, started: false , finished: false, board_2_id:@board_2.id )
      @board_1.game_id=@game.id
      @board_2.game_id=@game.id
      @board_2.save
      @board_1.save
      @attack="1 - 1"

  	
  	end

  	def teardown
  		Game.where(user_id:@user.id).destroy_all
  		Board.where(user_id:@user.id).destroy_all
  		Board.where(user_id:@player_2.id).destroy_all
  		User.where(username:"my_test").destroy_all
  		User.where(username:"my_juanma").destroy_all
      Ship.where(board_id:@board_1.id).destroy_all
      Play.where(user_id:@player_2_id,board_id:@board_1.id).destroy_all
  	end
  	
    def test_get_root
	    get '/'
	    assert_equal 200, last_response.status
  	end

  def test_register_invalid_user
    post '/players', user: { username:" ",password:"12345",name:"capitancomanche"}
    assert_equal 400, last_response.status
  end
	def test_get_players
		get '/players'
		assert_equal 200,last_response.status
	end 
  
  def test_signup
  	post '/players', user:{ username:"test_post",password: "1234",name:"Juancito Perez"}
  	assert_equal 201, last_response.status
  	User.where(username:"test_post").destroy_all
  end

  def test_signup_conflict
  	User.create(username:"test_post",password: "1234",full_name:"Tiffany Hwang")
  	post '/players', user:{ username:"test_post",password: "1234",name:"Juancito Perez"}
  	assert_equal 409, last_response.status
  	User.where(username:"test_post").destroy_all
  end

  def test_login
  	post '/auth/login', user:{username:@user.username,password:@user.password}
  	assert_equal 302, last_response.status
  	#asssert_redirected_to("/home")
  	get '/logout'
  end

  def test_not_login
  	post '/auth/login', user:{username:@user.username,password:"incorrect_pass"}
  	assert_equal 403, last_response.status
  	get '/logout'  	
  end

  def test_create_game
  	post '/auth/login', user:{username:@user.username,password:@user.password}
  	post '/players/@user.id/games', {board:"5", player:@player_2.id}
  	assert_equal 201, last_response.status  
  	Game.where(user_id:@user.id).destroy_all
  end

  def test_not_create_game
  	post '/auth/login', user:{username:@user.username,password:@user.password}
  	post '/players/@user.id/games', {board:"888", player:@player_2.id}
  	assert_equal 400, last_response.status  	
  end

  def test_ver_partida
  	post '/auth/login', user:{username:@user.username,password:@user.password}
  	get '/players/@user.id/games/'+@game.id.to_s
  	assert_equal 200, last_response.status 
  end

  def test_listar_partidas
  	get '/players/'+@user.id.to_s+'/games'
  	assert_equal 200, last_response.status
  end
  def test_put_ship
  	post '/auth/login', user:{username:@user.username,password:@user.password}
    put '/players/'+@user.id.to_s+'/games/'+@game.id.to_s
    assert_equal 200, last_response.status
  end

  def test_make_a_play_not_my_turn
    post '/auth/login', user:{username:@user.username,password:@user.password}
    post '/players/'+@user.id.to_s+'/games/'+@game.id.to_s+'/move', attacked_board: @board_2.id, attack: @attack
    assert_equal 403, last_response.status
  end
  
  def test_make_a_play_my_turn
    post '/auth/login', user:{username:@player_2.username,password:@player_2.password}
    post '/players/'+@player_2.id.to_s+'/games/'+@game.id.to_s+'/move', attacked_board: @board_1.id, attack: @attack
    assert_equal 201, last_response.status
  end
 
end
