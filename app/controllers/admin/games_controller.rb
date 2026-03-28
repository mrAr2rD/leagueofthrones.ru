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
      raw = params[:game][:game_results_attributes]
      return if raw.blank?

      # Normalize nested hash structure into flat array of attribute hashes
      rows = raw.values.map { |v| v.is_a?(Hash) && v.values.first.is_a?(Hash) ? v.values.first : v }
      allowed = %w[id player_id place points capitals dragons castles]

      GameResult.transaction do
        rows.each do |attrs|
          attrs = attrs.permit(*allowed)
          existing = attrs[:id].present? ? @game.game_results.find_by(id: attrs[:id]) : nil

          if attrs[:player_id].blank?
            existing&.destroy!
            next
          end

          clean = attrs.to_h.except("id").transform_values { |v| v.presence }

          if existing
            existing.update!(clean)
          else
            @game.game_results.create!(clean)
          end
        end
      end
    end
  end
end
