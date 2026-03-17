class LeaderboardController < ApplicationController
  def index
    @rankings = RankingCalculator.call
    @tours = Tour.ordered
  end
end
