class CitiesController < ApplicationController
  # Корень всегда ведёт на дефолтный город (первый по позиции, обычно Москва).
  # Переключение между городами — через переключатель в шапке. Отдельной
  # страницы выбора нет; пустой экран показываем только если городов ещё нет.
  def index
    default_city = City.ordered.first
    redirect_to city_leaderboard_path(default_city) if default_city
  end
end
