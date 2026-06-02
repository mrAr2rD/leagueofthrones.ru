module Admin
  class ToursController < BaseController
    before_action :set_tour, only: [ :show, :edit, :update, :destroy ]
    before_action :authorize_tour!, only: [ :show, :edit, :update, :destroy ]

    def index
      @city = accessible_cities.find_by(slug: params[:city]) if params[:city].present?
      scope = Tour.where(city: accessible_cities)
                  .includes(:city, games: :game_results)
                  .order(:city_id, :number)
      scope = scope.where(city: @city) if @city
      @tours = scope
    end

    def show
      @games = @tour.games.ordered.includes(game_results: :player)
    end

    def new
      city = accessible_cities.find_by(slug: params[:city]) || accessible_cities.first
      @tour = Tour.new(
        city: city,
        format: city&.default_format,
        number: city ? (city.tours.maximum(:number).to_i + 1) : nil
      )
    end

    def create
      @tour = Tour.new(tour_params)
      authorize_city!(@tour.city)
      return if performed?

      if @tour.save
        @tour.sync_tables
        redirect_to admin_tour_path(@tour), notice: "Тур создан"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      authorize_city!(City.find_by(id: tour_params[:city_id])) if tour_params.key?(:city_id)
      return if performed?

      if @tour.update(tour_params)
        @tour.sync_tables
        redirect_to admin_tour_path(@tour), notice: "Тур обновлён"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @tour.destroy
      redirect_to admin_tours_path, notice: "Тур удалён"
    end

    private

    def set_tour
      @tour = Tour.find(params[:id])
    end

    def authorize_tour!
      authorize_city!(@tour.city)
    end

    def tour_params
      params.expect(tour: [ :city_id, :number, :format, :tables_count, :played_on, :played, :starts_on, :ends_on ])
    end
  end
end
