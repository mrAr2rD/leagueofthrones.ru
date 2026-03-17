module Admin
  class SessionsController < BaseController
    skip_before_action :require_admin!, only: [ :new, :create ]
    layout "admin"

    def new
    end

    def create
      admin = AdminUser.find_by(login: params[:login])
      if admin&.authenticate(params[:password])
        session[:admin_user_id] = admin.id
        redirect_to admin_root_path, notice: "Вы вошли в систему"
      else
        flash.now[:alert] = "Неверный логин или пароль"
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      session.delete(:admin_user_id)
      redirect_to admin_login_path, notice: "Вы вышли из системы"
    end
  end
end
