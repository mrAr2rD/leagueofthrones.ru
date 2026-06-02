module Admin
  class PlayersController < BaseController
    before_action :set_player, only: [ :edit, :update, :destroy ]
    before_action :authorize_player!, only: [ :edit, :update, :destroy ]

    def index
      @players =
        if superadmin?
          Player.order(:last_name, :first_name)
        else
          Player.joins(:player_cities)
                .where(player_cities: { city_id: accessible_city_ids })
                .distinct
                .order(:last_name, :first_name)
        end
    end

    def new
      @player = Player.new
    end

    def create
      @player = Player.new(player_params)
      if @player.save
        @player.city_ids = resolved_city_ids([])
        redirect_to admin_players_path, notice: "Игрок создан"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      existing_ids = @player.city_ids
      if @player.update(player_params)
        @player.city_ids = resolved_city_ids(existing_ids)
        redirect_to admin_players_path, notice: "Игрок обновлён"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      return redirect_to admin_players_path, alert: "Удалять игроков может только супер-админ" unless superadmin?

      @player.destroy
      redirect_to admin_players_path, notice: "Игрок удалён"
    end

    private

    def set_player
      @player = Player.find(params[:id])
    end

    def authorize_player!
      return if superadmin?
      return if (@player.city_ids & accessible_city_ids).any?

      redirect_to admin_players_path, alert: "Нет доступа к этому игроку"
    end

    # city_ids обрабатываются отдельно (resolved_city_ids), поэтому используем
    # permit, а не expect — частичный апдейт без базовых полей не должен падать.
    def player_params
      params.fetch(:player, {}).permit(:first_name, :last_name, :nickname, :photo, :participates_in_tournament)
    end

    def submitted_city_ids
      Array(params.dig(:player, :city_ids)).reject(&:blank?).map(&:to_i)
    end

    # Супер-админ задаёт города как есть. Обычный админ меняет привязку только
    # к своим городам; привязки игрока к чужим городам сохраняются.
    def resolved_city_ids(existing_ids)
      return submitted_city_ids if superadmin?

      preserved = existing_ids - accessible_city_ids
      ((submitted_city_ids & accessible_city_ids) + preserved).uniq
    end
  end
end
