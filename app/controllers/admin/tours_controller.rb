module Admin
  class ToursController < BaseController
    before_action :set_tour, only: [ :show, :edit, :update ]

    def index
      @tours = Tour.ordered.includes(games: :game_results)
    end

    def show
      @games = @tour.games.ordered.includes(game_results: :player)
    end

    def edit
    end

    def update
      if @tour.update(tour_params)
        redirect_to admin_tour_path(@tour), notice: "Тур обновлён"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_tour
      @tour = Tour.find(params[:id])
    end

    def tour_params
      params.expect(tour: [ :number, :played_on, :played, :starts_on, :ends_on ])
    end
  end
end
