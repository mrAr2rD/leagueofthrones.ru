module Admin
  class GamesController < BaseController
    before_action :set_tour_and_game

    def edit
      @players = Player.order(:last_name)
      ensure_result_slots
    end

    def update
      save_results
      RankingCalculator.recalculate!
      redirect_to admin_tour_path(@tour), notice: "Результаты сохранены"
    rescue ActiveRecord::RecordInvalid => e
      @players = Player.order(:last_name)
      flash.now[:alert] = "Ошибка: #{e.message}"
      ensure_result_slots
      render :edit, status: :unprocessable_entity
    end

    private

    def set_tour_and_game
      @tour = Tour.find(params[:tour_id])
      @game = @tour.games.find(params[:id])
    end

    def ensure_result_slots
      existing = @game.game_results.size
      (8 - existing).times { @game.game_results.build }
    end

    def save_results
      results_params = params.expect(game: { game_results_attributes: [
        [ :id, :player_id, :place, :points, :capitals, :dragons, :castles, :_destroy ]
      ] })

      GameResult.transaction do
        results_params[:game_results_attributes].each do |attrs|
          next if attrs[:player_id].blank?

          if attrs[:id].present?
            result = @game.game_results.find(attrs[:id])
            result.update!(attrs.except(:id, :_destroy))
          else
            @game.game_results.create!(attrs.except(:id, :_destroy))
          end
        end
      end
    end
  end
end
