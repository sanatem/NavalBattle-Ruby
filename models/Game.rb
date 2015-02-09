class Game < ActiveRecord::Base

  def self.decide_win(id_game,user_session)

    ships=Board.find_by(user_id:user_session,game_id:id_game).alive_ships
    if ships > 0
      "game/winner".to_sym
    else
      "game/loser".to_sym
    end

  end   




end
