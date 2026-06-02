class GalleryController < ApplicationController
  before_action :require_gallery_auth!, only: :show

  def show
    @players = Player.includes(:cities).order(:last_name, :first_name)
  end

  def login
  end

  def authenticate
    admin = AdminUser.find_by(login: params[:login])
    if admin&.authenticate(params[:password])
      session[:gallery_authenticated] = true
      redirect_to gallery_path, notice: "Добро пожаловать в галерею"
    else
      flash.now[:alert] = "Неверный логин или пароль"
      render :login, status: :unprocessable_entity
    end
  end

  private

  def require_gallery_auth!
    unless session[:gallery_authenticated]
      redirect_to gallery_login_path
    end
  end
end
