module Admin
  class GamesController < BaseController
    RESULT_ATTRIBUTES = %w[
      player_id house place points capitals capital_captures capital_controls
      lands skulls dragons castles
    ].freeze

    # Счётчики с NOT NULL и дефолтом 0 в БД. Пустое поле в форме (админ стёр
    # значение) должно означать «0», а не NULL — иначе insert_all! падает
    # PG::NotNullViolation (валидации это пропускают, allow_nil: true).
    NOT_NULL_COUNTERS = %w[capitals dragons castles].freeze

    before_action :set_tour_and_game
    before_action -> { authorize_city!(@tour.city) }
    before_action :load_form_options, only: [ :edit, :update ]

    def edit
      ensure_result_slots
    end

    def update
      save_results
      RankingCalculator.recalculate!(@tour.city)
      redirect_to admin_tour_path(@tour), notice: "Результаты сохранены"
    rescue ActiveRecord::RecordInvalid => e
      messages = e.record.errors.map(&:message).presence || [ e.message ]
      flash.now[:alert] = "Ошибка: #{messages.join(', ')}"
      ensure_result_slots
      render :edit, status: :unprocessable_entity
    end

    private

    def set_tour_and_game
      @tour = Tour.find(params[:tour_id])
      @game = @tour.games.find(params[:id])
    end

    def load_form_options
      @players = @tour.city.players.to_a.sort_by { |player| [ player.admin_option_label.downcase, player.id ] }
      @player_options = @players.map { |player| [ player.admin_option_label, player.id ] }
      @player_options_by_selected = build_player_options_by_selected
      @player_tour_table_warnings = build_player_tour_table_warnings
      @house_options = GameResult.house_options(format: @tour.game_format)
      @player_house_options = build_player_house_options
    end

    def ensure_result_slots
      existing = @game.game_results.size
      (@tour.game_format.players_per_table - existing).times { @game.game_results.build }
    end

    def build_player_house_options
      historical_houses = GameResult.where(player_id: @players.map(&:id))
                                    .where.not(game_id: @game.id)
                                    .where.not(house: nil)
                                    .pluck(:player_id, :house)

      used_houses_by_player = historical_houses.each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |(player_id, house), hash|
        hash[player_id] << house
      end

      @players.each_with_object({}) do |player, options|
        options[player.id.to_s] = GameResult.house_options_for(
          used_houses: used_houses_by_player[player.id],
          format: @tour.game_format
        )
      end
    end

    def build_player_options_by_selected
      options = { "" => selectable_player_options }

      @players.each do |player|
        options[player.id.to_s] = selectable_player_options(selected_player_id: player.id)
      end

      options
    end

    def selectable_player_options(selected_player_id: nil)
      @players.filter_map do |player|
        [ player.admin_option_label, player.id ]
      end
    end

    def build_player_tour_table_warnings
      table_order = Game::TABLE_LETTERS.each_with_index.to_h
      rows = @tour.game_results
                  .joins(:game)
                  .where.not(game_id: @game.id)
                  .distinct
                  .pluck(:player_id, "games.table_letter")

      rows.each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |(player_id, table_letter), warnings|
        warnings[player_id.to_s] << table_letter
      end.transform_values do |table_letters|
        table_letters.uniq.sort_by { |table_letter| table_order.fetch(table_letter, table_letter) }
      end
    end

    def save_results
      raw = params[:game][:game_results_attributes]
      return if raw.blank?

      allowed = [ "id", *RESULT_ATTRIBUTES ]

      # Unwrap double-nested params: {"29"=>{"0"=>{"id"=>"29",...}}} -> {"id"=>"29",...}
      rows = raw.values.map do |value|
        inner = value.respond_to?(:values) && value.values.first.respond_to?(:permit) ? value.values.first : value
        inner.permit(*allowed)
      end

      ensure_rows_complete!(rows)

      current_results = @game.game_results.index_by { |result| result.id.to_s }
      submitted_results = rows.filter_map do |attrs|
        next if row_blank?(attrs)

        result = current_results[attrs[:id].to_s] || @game.game_results.build
        result.assign_attributes(clean_result_attributes(attrs))
        result
      end

      replace_form_results(submitted_results)
      invalid_result = submitted_results.detect { |result| !result.valid? }
      raise ActiveRecord::RecordInvalid.new(invalid_result) if invalid_result

      timestamp = Time.current
      result_rows = submitted_results.map do |result|
        result.attributes.slice("game_id", *RESULT_ATTRIBUTES).merge(
          "created_at" => result.persisted? ? result.created_at : timestamp,
          "updated_at" => timestamp
        )
      end

      GameResult.transaction do
        GameResult.where(game_id: @game.id).delete_all
        GameResult.insert_all!(result_rows) if result_rows.any?
      end

      @game.game_results.reset
    end

    def clean_result_attributes(attrs)
      attrs.to_h.slice(*RESULT_ATTRIBUTES).to_h do |key, value|
        cleaned = value.presence
        cleaned = 0 if cleaned.nil? && NOT_NULL_COUNTERS.include?(key)
        [ key, cleaned ]
      end
    end

    def ensure_rows_complete!(rows)
      incomplete_rows = rows.reject { |attrs| row_blank?(attrs) || row_complete?(attrs) }
      return if incomplete_rows.empty?

      @game.errors.add(:base, "Заполните игрока и дом в каждой занятой строке или очистите строку целиком")
      raise ActiveRecord::RecordInvalid.new(@game)
    end

    def row_blank?(attrs)
      attrs[:player_id].blank? && attrs[:house].blank?
    end

    def row_complete?(attrs)
      attrs[:player_id].present? && attrs[:house].present?
    end

    def replace_form_results(results)
      association = @game.association(:game_results)
      association.target = results
      association.loaded!
    end
  end
end
