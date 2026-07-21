module Admin
  class StatisticsController < BaseController
    SORT_METRICS = %w[captures dragons skulls].freeze

    def show
      @cities = accessible_cities.to_a
      if @cities.empty?
        redirect_to admin_root_path, alert: "Нет доступных городов"
        return
      end

      @city = selected_city
      return if performed?

      @game_format = selected_game_format
      @statistics = TournamentStatisticsCalculator.call(
        city: @city,
        format: @game_format
      )
      @sort_metric = selected_sort_metric
      @statistics_rows = sorted_statistics_rows
      load_publication_state
    end

    private

    def selected_city
      return @cities.first if params[:city].blank?

      city = City.find_by!(slug: params[:city])
      authorize_city!(city)
      city unless performed?
    end

    def selected_game_format
      key = params[:game_format].presence || @city.default_format
      GameFormat::FORMATS[key] || @city.default_game_format
    end

    def selected_sort_metric
      metric = params[:sort].to_s
      available_sort_metrics.include?(metric) ? metric : "captures"
    end

    def available_sort_metrics
      SORT_METRICS.select do |metric|
        metric == "captures" ||
          (metric == "dragons" && @game_format.tracks_dragons?) ||
          (metric == "skulls" && @game_format.tracks_skulls?)
      end
    end

    def sorted_statistics_rows
      tie_breakers = available_sort_metrics - [ @sort_metric ]

      @statistics.rows.sort_by do |row|
        [
          -row.public_send(@sort_metric),
          *tie_breakers.map { |metric| -row.public_send(metric) },
          row.player.display_name.to_s.downcase,
          row.player.nickname.to_s.downcase,
          row.player.id
        ]
      end
    end

    def load_publication_state
      @published_awards = AchievementAward
                          .for_tournament(city: @city, game_format: @game_format.key)
                          .published
                          .includes(:player, :awarded_by)
                          .order(:achievement_key, :player_id)
                          .to_a
      @published_awards_by_key = @published_awards.group_by(&:achievement_key)
      @published_at = @published_awards.filter_map(&:published_at).max
      @published_snapshot_differs = published_snapshot_differs?
    end

    def published_snapshot_differs?
      return false if @published_awards.empty?

      calculated = @statistics.nominations.flat_map do |nomination|
        nomination.leaders.map do |leader|
          [ nomination.definition.key, leader.player.id, nomination.max_value ]
        end
      end.sort
      published = @published_awards.map do |award|
        [ award.achievement_key, award.player_id, award.stat_value ]
      end.sort

      calculated != published
    end
  end
end
