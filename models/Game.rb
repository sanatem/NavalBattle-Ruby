class Game < ActiveRecord::Base

  validates :board_1_id,:player_2_id,:user_id,:id_turno, presence:true
  
  def self.decide_win(id_game,user_session)

    ships=Board.find_by(user_id:user_session,game_id:id_game).alive_ships
    if ships > 0
      "game/winner".to_sym
    else
      "game/loser".to_sym
    end

  end

  #This starts an attack in the board
  def make_the_play(play)
   ship=Ship.find_by(coorX:play.coorX,coorY:play.coorY,board_id:play.board_id)
   if !ship.nil? and ship.state!= false
    #Lo hunde, it hurts :(
     ship.state=false
     ship.save
     #Descontamos el total de barcos vivos
     board=Board.find(play.board_id)
     board.alive_ships=board.alive_ships-1
     board.save
     #The game ends
     if board.alive_ships==0
       self.finished=true
       self.started=false
       self.save
     end
   
   end
  	   	  
  end   
  #Turn control
  def change_turn
    player_1=self.user_id
    player_2=self.player_2_id
    if(self.id_turno==player_1)
       self.id_turno=player_2
    else
       self.id_turno=player_1
    end
    self.save  	
  end

  def add_2nd_player id_user
    board_1=Board.find(self.board_1_id)
      
    @board=Board.create(size:board_1.size, max_ships:board_1.max_ships ,user_id: id_user,game_id:self.id,alive_ships:board_1.max_ships)
      
    self.board_2_id=@board.id
    self.save #This saves the 2nd player board  	
  	
  	@board #Returns the board of the second player
  end

  def start_ok
    board_1=Board.find(self.board_1_id)
    board_2=Board.find(self.board_2_id)
    if board_1.ships.size == board_1.max_ships and board_2.ships.size == board_2.max_ships 
      true
    else
      false
    end
  end


end
