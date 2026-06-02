class PlayersController < ApplicationController
  include CityScoped

  def show
    @player = @city.players.find(params[:id])
    @results = @player.game_results
                      .joins(game: :tour)
                      .where(tours: { city_id: @city.id })
                      .includes(game: :tour)
                      .order("tours.number ASC, games.table_letter ASC, game_results.id ASC")
    ranked = RankingCalculator.call(@city).find { |rp| rp.player.id == @player.id }
    @league = ranked&.league || :iron
  end
end
