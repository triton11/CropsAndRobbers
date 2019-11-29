class RoomsController < ApplicationController
  protect_from_forgery with: :null_session

  before_action :set_room, only: [:show, :edit, :update, :destroy, :farm]

  # GET /rooms
  # GET /rooms.json
  def index
    @rooms = Room.all
  end

  def farm
    set_room
    puts("Farming!")
    player = @room.players.find_by(id: params[:player_id])
    score = player.score
    player.update({score: score+1, busy_until: Time.now + 10 })
    player.save

    respond_to do |format|
      format.js { render json: {} }
    end
  end

  def guard
    set_room
    puts("Guarding!")
    puts(@room.players)
    player = @room.players.find_by(id: params[:player_id])
    player_affected = @room.players.find_by(id: params[:player_affected])
    player.update({visiting: player_affected.name, busy_until: Time.now + 10 })
    player.save

    respond_to do |format|
      format.js { render json: {} }
    end
  end

  def rob
    set_room
    player = @room.players.find_by(id: params[:player_id])
    player_affected = @room.players.find_by(id: params[:player_affected])
    shot = false
    @room.players.each do |p|
      puts(p.busy_until)
      if p&.visiting == player_affected.name && p.role == "farmer" && p&.busy_until > Time.now
        shot = true
      end
    end
    if (player_affected&.busy_until > Time.now && shot == false)
      player_affected_new_score = player.score + player_affected.score
      player_affected.update({score: 0})
      player_affected.save
      player.update({score: player_affected_new_score})
      player.save
    end
    if (player_affected&.busy_until > Time.now && shot == true)
      lives_remaining = player.lives - 1
      player.update({lives: lives_remaining})
      player.save
    end

    respond_to do |format|
      format.js { render json: {} }
    end
  end

  def start
    set_room
    thief = @room.players.sample
    thief.update(role: "thief")
    (@room.players - [thief]).each do |player|
      player.update(role: "farmer")
    end
    respond_to do |format|
      format.html { redirect_to @room, notice: "Game start!" }
    end
  end

  def end
    set_room
    @room.players.each do |player|
      player.destroy
    end
    @room.destroy
    respond_to do |format|
      format.html { redirect_to "/", notice: "Game end!" }
    end
  end

  # GET /rooms/1
  # GET /rooms/1.json
  def show
  end

  # GET /rooms/new
  def new
    @room = Room.new
  end

  # GET /rooms/1/edit
  def edit
  end

  # POST /rooms
  # POST /rooms.json
  def create
    player_params = {"name"=>room_params[:leader], "score"=>0, "lives"=>3}
  
    @room = Room.new(room_params)

    respond_to do |format|
      if @room.save
        @player = @room.players.create(player_params)
        if @player.save
          session[:player_id] = @player.id
          format.html { redirect_to @room, notice: 'Room and Player were successfully created.' }
          format.json { render :show, status: :created, location: @room }
        else
          format.html { render :new }
          format.json { render json: @room.errors, status: :unprocessable_entity }
        end
      else
        format.html { render :new }
        format.json { render json: @room.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /rooms/1
  # PATCH/PUT /rooms/1.json
  def update
    respond_to do |format|
      if @room.update(room_params)
        format.html { redirect_to @room, notice: 'Room was successfully updated.' }
        format.json { render :show, status: :ok, location: @room }
      else
        format.html { render :edit }
        format.json { render json: @room.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /rooms/1
  # DELETE /rooms/1.json
  def destroy
    @room.destroy
    respond_to do |format|
      format.html { redirect_to rooms_url, notice: 'Room was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_room
      @room = Room.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def room_params
      params.require(:room).permit(:code, :leader)
    end
end
