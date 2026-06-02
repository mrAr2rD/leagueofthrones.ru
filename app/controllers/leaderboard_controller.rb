class LeaderboardController < ApplicationController
  include CityScoped

  def index
    @tours = @city.tours.ordered
    if params[:tour].present?
      @selected_tour = @city.tours.find_by(number: params[:tour])
      if @selected_tour
        @games = @selected_tour.games.ordered.includes(game_results: :player)
      end
    end
    @rankings = RankingCalculator.call(@city) unless @selected_tour
  end
end
