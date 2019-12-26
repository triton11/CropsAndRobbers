class PlayersController < ApplicationController
  protect_from_forgery with: :null_session
  before_action :set_player, only: [:show, :edit, :update, :destroy]

  # GET /players
  # GET /players.json
  def index
    @players = Player.all
  end

  def info
    set_player
    notice = nil
    investigated = []
    puts("====================")
    puts("Player: ", @player.name)
    puts("visiting?", @player.visiting)
    Player.all.each do |p|
      unless(p == @player) 
        puts("-------------------")
        puts("Checking: ", p.name)
        puts("busy_until: ", p&.busy_until)
        puts("visiting? ", p.visiting)
        if p.visiting == @player.visiting && p.role == "thief" && @player.role == "farmer" && p&.busy_until > Time.now && p.visiting != ""
          notice = "You shot someone!"
        end
        if p.visiting == @player.visiting && @player.role == "investigator" && p&.busy_until > Time.now
          investigated << p.name
        end
      end
    end
    if (investigated.any?)
      puts("Found : ", investigated)
      notice = "While at #{@player.visiting}, you saw " + investigated.join(", ")
    end
    puts("====================")
    respond_to do |format|
      format.js { render json: {"score"=>@player.score, "lives"=>@player.lives, "notice"=> notice} }
    end
  end

  def clear
    set_player
    @player.update({visiting: ""})
    respond_to do |format|
      format.js { render json: "" }
    end
  end

  # GET /players/1
  # GET /players/1.json
  def show
  end

  # GET /players/new
  def new
    @player = Player.new
  end

  # GET /players/1/edit
  def edit
  end

  # POST /players
  # POST /players.json
  def create
    p = {"name"=>player_params[:name]}

    @player = Player.new(p)
    @room = Room.find_by(code: player_params[:room])
    @room.players << @player

    respond_to do |format|
      if @player.save
        session[:player_id] = @player.id
        format.html { redirect_to @room, notice: 'Player was successfully added to room.' }
        format.json { render :show, status: :created, location: @room }
      else
        format.html { render :new }
        format.json { render json: @player.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /players/1
  # PATCH/PUT /players/1.json
  def update
    respond_to do |format|
      if @player.update(player_params)
        format.html { redirect_to @player, notice: 'Player was successfully updated.' }
        format.json { render :show, status: :ok, location: @player }
      else
        format.html { render :edit }
        format.json { render json: @player.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /players/1
  # DELETE /players/1.json
  def destroy
    puts("destroyed")
    @player.destroy
    respond_to do |format|
      format.html { redirect_to players_url, notice: 'Player was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_player
      @player = Player.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def player_params
      params.require(:player).permit(:name, :room, :role, :score, :lives)
    end

    def log_in
      session[:player_id] = @player.id
    end
end
