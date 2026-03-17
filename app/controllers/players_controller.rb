class PlayersController < ApplicationController
  def show
    @player = Player.find(params[:id])
    @results = @player.game_results.includes(game: :tour).order("tours.number ASC")
  end
end
