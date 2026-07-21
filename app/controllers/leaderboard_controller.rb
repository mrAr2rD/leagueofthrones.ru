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
    return if @selected_tour

    @rankings = RankingCalculator.call(@city)
    @achievement_awards_by_player_id = AchievementAward
                                          .published
                                          .where(city: @city, player_id: @rankings.map { |ranking| ranking.player.id })
                                          .order(:achievement_key, :game_format)
                                          .group_by(&:player_id)
  end
end
