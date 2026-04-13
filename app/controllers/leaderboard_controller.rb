class LeaderboardController < ApplicationController
  def index
    @tours = Tour.ordered
    if params[:tour].present?
      @selected_tour = Tour.find_by(number: params[:tour])
      if @selected_tour
        @games = @selected_tour.games.ordered.includes(game_results: :player)
      end
    end
    @rankings = RankingCalculator.call unless @selected_tour
  end
end
