module Admin
  class PagesController < BaseController
    before_action :set_page

    def edit
    end

    def update
      if @page.update(page_params)
        redirect_to edit_admin_page_path(@page.slug), notice: "Страница обновлена"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_page
      @page = SitePage.find_by!(slug: params[:slug])
    end

    def page_params
      params.expect(site_page: [ :title, :content ])
    end
  end
end
