class RoomsController < ApplicationController
  protect_from_forgery with: :null_session

  before_action :set_room, only: [:show, :edit, :update, :destroy, :farm]

  # GET /rooms
  # GET /rooms.json
  def index
    @rooms = Room.all
  end

  def round
    set_room
    respond_to do |format|
      format.js { render json: {round: @room.round, players: @room.players.map{|p| p.name} } }
    end
  end

  def next_round
    set_room
    respond_to do |format|
      format.js { render json: {round: @room.round, round_end: @room.round_end} }
    end
  end

  # This is where the magic happens, baby. Yep. This one massive function.
  def calculate_state
    set_room

    # params[:round].to_i >= @room.number_of_rounds checks if you have reached the final round.
    # params[:round].to_i < @room.round checks if you are NOT the first person to finish, 
    # because the first person needs to calculate the state.
    if (params[:round].to_i >= @room.number_of_rounds && params[:round].to_i < @room.round)
      respond_to do |format|
        format.js { render json: {game_over: "true"}  }
      end
      return
    elsif (params[:round].to_i < @room.round)
      respond_to do |format|
        format.js { render json: {} }
      end
      return
    end

    # If neither of the last two statements were true, then you are the first person
    # whose round has ended and you can calculate the state.
    players = @room.players
    players_array = []
    players.each do |player|
      players_array << player.attributes
    end

    players_array.each do |player|
      player["last_round_notice"] = " "
    end

    # Farmers first. If they farmed, +1 crop. Easy.
    players_array.select { |p| p["activity"] == "farming" }.each do |farmer|
      score = farmer["score"]
      farmer["score"] = score + 1
    end

    # Donators next - also easy. Give +1 to whoever they visit.
    players_array.select { |p| p["activity"] == "donating" }.each do |donator|
      player_affected = players_array.select{ |v| v["name"] == donator["visiting"] }[0]
      score = player_affected["score"]
      player_affected["score"] = score + 1
    end

    # Investigators are a little trickier. Loop through and see if anyone else visited
    # the same room as an investigator, set their status accordingly.
    players_array.select { |p| p["activity"] == "investigating" }.each do |investigator|
      investigated = []
      player_affected = players_array.select{ |v| v["name"] == investigator["visiting"] }[0]
      players_array.select {|p| p["id"] != investigator["id"] }.each do |player|
        if player["visiting"] == player_affected["name"]
          investigated.append(player["name"])
        end
      end
      if investigated.empty?
        investigated << "nobody"
      end
      notice = "While at #{investigator['visiting']}, you saw " + investigated.join(", ")
      investigator["last_round_notice"] = notice
    end

    # Robbing / gaurding is last. For each robber, do the following:
    players_array.select { |p| p["activity"] == "robbing" }.each do |robber|
      shot = false
      player_affected = players_array.select{ |v| v["name"] == robber["visiting"] }[0]

      # First, loop and see if the robbed player was gaurded, and update
      # the gaurds status.
      players_array.select do |p| 
        p["activity"] == "guarding" && p["visiting"] == player_affected["name"] 
      end.each do |guard|
        guard["last_round_notice"] = "You shot someone!"
        shot = true
      end

      # Was the robber shot by a gaurd? If so, change lives. Else, update 
      # the farmer and robbers crop totals.
      if shot == true
        lives_remaining = robber["lives"] - 1
        robber["last_round_notice"] = "You were shot!"
        robber["lives"] = lives_remaining
      else
        max_payoff = players_array.size - @room.robber_count
        robber_new_score = (player_affected["score"] > max_payoff - 1) ? robber["score"] + max_payoff : robber["score"] + player_affected["score"]
        player_affected_new_score = (player_affected["score"] > max_payoff - 1) ? player_affected["score"] - max_payoff : 0
        player_affected["last_round_notice"] = "You were robbed!"
        player_affected["score"] = player_affected_new_score
        robber["last_round_notice"] = "Success!"
        robber["score"] = robber_new_score
      end
    end

    # Reset each player's activity and visiting, and re-save players
    players.each do |player|
      updated_attribs = players_array.select{ |p| p["id"] == player.id }[0]
      updated_attribs["activity"] = nil
      updated_attribs["visiting"] = nil
      player.update(updated_attribs)
    end

    @room.round = @room.round + 1
    @room.round_end = Time.now.to_i + @room.time_per_round
    @room.save

    # If last round, game is now over
    if (@room.round > @room.number_of_rounds)
      respond_to do |format|
        format.js { render json: {game_over: "true"} }
      end
    else
      respond_to do |format|
        format.js { render json: {} }
      end
    end
  end

  def set_activity
    set_room
    player = @room.players.find_by(id: params[:player_id])
    visiting = (params[:player_affected] == "undefined") ? " " : @room.players.find_by(id: params[:player_affected]).name
    player.update({ activity: params[:activity], round: params[:round], visiting: visiting })
    # player.save
    respond_to do |format|
      format.js { render json: {} }
    end
  end

  def start
    set_room
    robbers = @room.players.sample(@room.robber_count)
    robbers.each do |player|
      player.update({role: "robber", "score"=>0, "lives"=>2})
    end
    farmers = (@room.players - robbers).sample(@room.farmer_count)
    farmers.each do |player|
      player.update({role: "farmer", "score"=>0, "lives"=>2})
    end
    investigators = ((@room.players - robbers) - farmers).sample(@room.investigator_count)
    investigators.each do |player|
      player.update({role: "investigator", "score"=>0, "lives"=>2})
    end
    donators = (((@room.players - robbers) - farmers) - investigators)
    donators.each do |player|
      player.update({role: "donator", "score"=>0, "lives"=>2})
    end
    @room.round = 1
    #This makes the Time UTC
    @room.round_end = Time.now.to_i + @room.time_per_round
    @room.save
    respond_to do |format|
      format.html { redirect_to @room, notice: "Game start!" }
    end
  end

  def end
    set_room
    @robber_total = 0
    @village_total = 0
    @room.players.each do |player|
      if player.role == "robber"
        @robber_total += player.score
      else
        @village_total += player.score
      end
    end
    respond_to do |format|
      format.html { render :game_over }
    end
  end

  def delete_everything
    set_room
    @room.players.each do |player|
      player.destroy
    end
    @room.destroy
    respond_to do |format|
      format.html { redirect_to "/" }
      format.json { redirect_to "/" }
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
  # This creates the leader player AND the room
  def create
    player_params = {"name"=>room_params[:leader], score: 0, lives: 2}
  
    @room = Room.new(room_params)
    @room.round = 0

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
      @server_time = Time.now.to_i
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def room_params
      params.require(:room).permit(:code, :leader, :farmer_count, :robber_count, :investigator_count, :donator_count, :number_of_rounds, :time_per_round)
    end
end
