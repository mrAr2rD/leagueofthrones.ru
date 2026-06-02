module Admin
  class BaseController < ApplicationController
    layout "admin"
    before_action :require_admin!

    private

    def require_admin!
      unless current_admin
        redirect_to admin_login_path, alert: "Необходимо войти в систему"
      end
    end

    def current_admin
      @current_admin ||= AdminUser.find_by(id: session[:admin_user_id])
    end
    helper_method :current_admin

    def superadmin?
      current_admin&.superadmin?
    end
    helper_method :superadmin?

    # Города, доступные текущему админу (супер-админу — все).
    def accessible_cities
      @accessible_cities ||= current_admin.accessible_cities
    end
    helper_method :accessible_cities

    def accessible_city_ids
      @accessible_city_ids ||= accessible_cities.pluck(:id)
    end

    def require_superadmin!
      redirect_to admin_root_path, alert: "Недостаточно прав" unless superadmin?
    end

    def authorize_city!(city)
      return if current_admin&.can_access_city?(city)

      redirect_to admin_root_path, alert: "Нет доступа к этому городу"
    end
  end
end
