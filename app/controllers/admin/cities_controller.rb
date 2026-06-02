module Admin
  class CitiesController < BaseController
    before_action :require_superadmin!
    before_action :set_city, only: [ :edit, :update, :destroy ]

    def index
      @cities = City.ordered.includes(:tours)
    end

    def new
      @city = City.new
    end

    def create
      @city = City.new(city_params)
      if @city.save
        redirect_to admin_cities_path, notice: "Город создан"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @city.update(city_params)
        redirect_to admin_cities_path, notice: "Город обновлён"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @city.destroy
      redirect_to admin_cities_path, notice: "Город удалён"
    end

    private

    def set_city
      # City#to_param возвращает slug, поэтому и в админке адресуем по slug.
      @city = City.find_by!(slug: params[:id])
    end

    def city_params
      params.expect(city: [ :name, :slug, :register_url, :default_format, :position ])
    end
  end
end
