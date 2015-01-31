# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150129210116) do

  create_table "boards", force: :cascade do |t|
    t.integer "size"
    t.integer "max_ships"
    t.integer "user_id"
  end

  add_index "boards", ["user_id"], name: "index_boards_on_user_id"

  create_table "games", force: :cascade do |t|
    t.integer "user_id"
    t.integer "board_id"
    t.integer "player_2_id"
    t.boolean "finalizado"
    t.boolean "comenzado"
  end

  add_index "games", ["user_id"], name: "index_games_on_user_id"

  create_table "ships", force: :cascade do |t|
    t.boolean "state"
    t.integer "coorX"
    t.integer "coorY"
    t.integer "board_id"
  end

  add_index "ships", ["board_id"], name: "index_ships_on_board_id"

  create_table "users", force: :cascade do |t|
    t.string "full_name"
    t.string "username"
    t.string "password"
  end
  create_table "plays", force: :cascade do |t|
    t.integer "coorX"
    t.integer "coorY"
    t.integer "user_id"
    t.boolean "valid"
  end
  add_index "plays", ["board_id"], name: "index_plays_on_board_id"
  #la idea seria agregar las plays de manera tal que tengan un user_id para saber si la play 
  #q se ejecuto sobre tal tablero corresponde al usuario contrario  o no , y el valid seria para descartar
  #las jugadas invalidas
  #tambien te agrege al game las booleanas que habiamos charlado
end
