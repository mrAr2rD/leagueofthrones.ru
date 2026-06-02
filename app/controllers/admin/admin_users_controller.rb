module Admin
  class AdminUsersController < BaseController
    before_action :require_superadmin!
    before_action :set_admin_user, only: [ :edit, :update, :destroy ]

    def index
      @admin_users = AdminUser.includes(:cities).order(:login)
    end

    def new
      @admin_user = AdminUser.new
    end

    def create
      @admin_user = AdminUser.new(admin_user_params)
      if @admin_user.save
        redirect_to admin_admin_users_path, notice: "Админ создан"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @admin_user.update(admin_user_params)
        redirect_to admin_admin_users_path, notice: "Админ обновлён"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @admin_user == current_admin
        redirect_to admin_admin_users_path, alert: "Нельзя удалить самого себя"
      elsif @admin_user.superadmin? && AdminUser.where(superadmin: true).count <= 1
        redirect_to admin_admin_users_path, alert: "Нельзя удалить последнего супер-админа"
      else
        @admin_user.destroy
        redirect_to admin_admin_users_path, notice: "Админ удалён"
      end
    end

    private

    def set_admin_user
      @admin_user = AdminUser.find(params[:id])
    end

    def admin_user_params
      permitted = params.expect(admin_user: [ :login, :password, :password_confirmation, :superadmin, city_ids: [] ])
      # При редактировании пустой пароль означает «не менять».
      permitted.delete(:password) if permitted[:password].blank?
      permitted.delete(:password_confirmation) if permitted[:password_confirmation].blank?
      permitted
    end
  end
end
