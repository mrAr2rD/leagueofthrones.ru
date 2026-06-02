module Admin
  class PlayersController < BaseController
    before_action :set_player, only: [ :edit, :update, :destroy ]

    def index
      @players = Player.order(:last_name, :first_name)
    end

    def new
      @player = Player.new
    end

    def create
      @player = Player.new(player_params)
      if @player.save
        redirect_to admin_players_path, notice: "Игрок создан"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @player.update(player_params)
        redirect_to admin_players_path, notice: "Игрок обновлён"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @player.destroy
      redirect_to admin_players_path, notice: "Игрок удалён"
    end

    private

    def set_player
      @player = Player.find(params[:id])
    end

    def player_params
      params.expect(player: [ :first_name, :last_name, :nickname, :photo, :participates_in_tournament, city_ids: [] ])
    end
  end
end
