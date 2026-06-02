class PagesController < ApplicationController
  include CityScoped

  def rules
    @page = @city.site_pages.find_by!(slug: "rules")
  end
end
