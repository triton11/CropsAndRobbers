# This controller just tracks logins for players
class SessionController < ApplicationController
	def new
		render 'session/new'
	end

	def create
	  	session[:player_id] = @player.id
	  	redirect_to @player
	end

	def destroy
		reset_session
		redirect_to('/')
	end
end