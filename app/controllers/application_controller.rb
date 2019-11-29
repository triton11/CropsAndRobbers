class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  helper_method def logged_in?
    session[:player_id]
  end

  helper_method def current_user
    @player = Player.find(session[:player_id]) if logged_in?
  end
end
