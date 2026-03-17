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
  end
end
