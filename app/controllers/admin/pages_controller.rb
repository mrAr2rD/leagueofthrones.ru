module Admin
  class PagesController < BaseController
    before_action :set_page, only: [ :edit, :update ]

    def index
      @pages = SitePage.includes(:city).order("cities.position", "site_pages.slug").references(:city)
    end

    def new
      @page = SitePage.new(city: City.find_by(slug: params[:city]) || City.ordered.first)
    end

    def create
      @page = SitePage.new(create_page_params)
      if @page.save
        redirect_to edit_admin_page_path(@page), notice: "Страница создана"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @page.update(page_params)
        redirect_to edit_admin_page_path(@page), notice: "Страница обновлена"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_page
      @page = SitePage.find(params[:id])
    end

    def page_params
      params.expect(site_page: [ :title, :content ])
    end

    # При создании дополнительно разрешаем выбрать город и slug.
    def create_page_params
      params.expect(site_page: [ :city_id, :slug, :title, :content ])
    end
  end
end
