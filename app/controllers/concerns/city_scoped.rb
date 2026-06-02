# Публичные контроллеры скоупятся городом из первого сегмента URL (/:city_id).
# Параметр называется :city_id (см. routes), значение — slug города.
module CityScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_city
  end

  private

  # Маршрут /:city_id — catch-all по первому сегменту, поэтому посторонний путь
  # (опечатка, чужой город) ведёт на выбор города, а не падает 500/404.
  def set_city
    @city = City.find_by(slug: params[:city_id])
    redirect_to root_path, alert: "Город не найден" if @city.nil?
  end
end
