class TidesOfBattleSessionsController < ApplicationController
  include CityScoped

  before_action :disable_browser_cache
  before_action :set_battle_session, except: :new

  rescue_from TidesOfBattleSession::InvalidTransition, with: :render_invalid_transition
  rescue_from ArgumentError, with: :render_invalid_side

  def new
    @battle_session = @city.tides_of_battle_sessions.create!
    redirect_to battle_session_path
  end

  def show
  end

  def draw
    @battle_session.draw!(params[:side])
    redirect_to battle_session_path, status: :see_other
  end

  def peek
    side = params[:side].to_s
    raise TidesOfBattleSession::InvalidTransition, "Сначала вытяните карту" unless @battle_session.card_drawn?(side)
    raise TidesOfBattleSession::InvalidTransition, "Карты уже раскрыты" if @battle_session.revealed?

    @peeked_side = side
    render :show
  end

  def reroll
    @battle_session.reroll!(params[:side])
    redirect_to battle_session_path, status: :see_other
  end

  def reveal
    @battle_session.reveal!
    redirect_to battle_session_path, status: :see_other
  end

  private

  def set_battle_session
    @battle_session = @city.tides_of_battle_sessions.find_by!(token: params[:token])
  end

  def disable_browser_cache
    response.headers["Cache-Control"] = "no-store"
  end

  def battle_session_path
    city_tides_of_battle_session_path(@city, @battle_session.token)
  end

  def render_invalid_transition(error)
    flash.now[:alert] = error.message
    render :show, status: :unprocessable_entity
  end

  def render_invalid_side
    head :not_found
  end
end
