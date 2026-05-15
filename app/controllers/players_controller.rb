class PlayersController < ApplicationController
  def show
    @player = Player.find(params[:id])
    @results = @player.game_results
                      .joins(game: :tour)
                      .includes(game: :tour)
                      .order("tours.number ASC, games.table_letter ASC, game_results.id ASC")
    ranked = RankingCalculator.call.find { |rp| rp.player.id == @player.id }
    @league = ranked&.league || :iron
  end
end
