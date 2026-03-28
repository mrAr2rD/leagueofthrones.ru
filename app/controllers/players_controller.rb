class PlayersController < ApplicationController
  def show
    @player = Player.find(params[:id])
    @results = @player.game_results.includes(game: :tour).order("tours.number ASC")
    ranked = RankingCalculator.call.find { |rp| rp.player.id == @player.id }
    @league = ranked&.league || :iron
  end
end
