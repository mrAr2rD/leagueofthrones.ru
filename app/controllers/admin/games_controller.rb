module Admin
  class GamesController < BaseController
    before_action :set_tour_and_game
    before_action :load_form_options, only: [ :edit, :update ]

    def edit
      ensure_result_slots
    end

    def update
      save_results
      RankingCalculator.recalculate!
      redirect_to admin_tour_path(@tour), notice: "Результаты сохранены"
    rescue ActiveRecord::RecordInvalid => e
      flash.now[:alert] = "Ошибка: #{e.message}"
      ensure_result_slots
      render :edit, status: :unprocessable_entity
    end

    private

    def set_tour_and_game
      @tour = Tour.find(params[:tour_id])
      @game = @tour.games.find(params[:id])
    end

    def load_form_options
      @players = Player.order(:last_name, :first_name, :nickname)
      @player_options = @players.map { |player| [ player.admin_option_label, player.id ] }
      @house_options = GameResult.house_options
    end

    def ensure_result_slots
      existing = @game.game_results.size
      (8 - existing).times { @game.game_results.build }
    end

    def save_results
      raw = params[:game][:game_results_attributes]
      return if raw.blank?

      allowed = %w[id player_id house place points capitals dragons castles]

      # Unwrap double-nested params: {"29"=>{"0"=>{"id"=>"29",...}}} -> {"id"=>"29",...}
      rows = raw.values.map do |value|
        inner = value.respond_to?(:values) && value.values.first.respond_to?(:permit) ? value.values.first : value
        inner.permit(*allowed)
      end

      GameResult.transaction do
        rows.each do |attrs|
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
