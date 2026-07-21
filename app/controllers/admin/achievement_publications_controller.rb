module Admin
  class AchievementPublicationsController < BaseController
    before_action :load_tournament

    def create
      publish_current_awards!(notice: "Достижения опубликованы")
    end

    def update
      publish_current_awards!(notice: "Опубликованные достижения обновлены")
    end

    def destroy
      timestamp = Time.current
      AchievementAward
        .for_tournament(city: @city, game_format: @game_format.key)
        .published
        .update_all(published_at: nil, updated_at: timestamp)

      redirect_to_statistics(notice: "Публикация достижений снята")
    end

    private

    def load_tournament
      @city = City.find(params[:city_id])
      authorize_city!(@city)
      return if performed?

      @game_format = GameFormat::FORMATS[params[:game_format].to_s]
      return if @game_format

      redirect_to admin_statistics_path(city: @city.slug), alert: "Неизвестный игровой формат"
    end

    def publish_current_awards!(notice:)
      statistics = TournamentStatisticsCalculator.call(
        city: @city,
        format: @game_format
      )

      unless statistics.complete?
        redirect_to_statistics(
          alert: "Публикация невозможна: сначала исправьте проблемы заполнения данных"
        )
        return
      end

      replace_published_awards!(statistics)
      redirect_to_statistics(notice: notice)
    end

    def replace_published_awards!(statistics)
      timestamp = Time.current
      scope = AchievementAward.for_tournament(
        city: @city,
        game_format: @game_format.key
      )

      AchievementAward.transaction do
        existing_awards = scope.lock.to_a
        existing_by_winner = existing_awards.index_by do |award|
          [ award.achievement_key, award.player_id ]
        end

        scope.published.update_all(published_at: nil, updated_at: timestamp)

        statistics.nominations.each do |nomination|
          nomination.leaders.each do |leader|
            identity = [ nomination.definition.key, leader.player.id ]
            award = existing_by_winner[identity] || scope.build(
              achievement_key: nomination.definition.key,
              player: leader.player
            )
            award.update!(
              stat_value: nomination.max_value,
              awarded_at: timestamp,
              published_at: timestamp,
              awarded_by: current_admin
            )
          end
        end
      end
    end

    def redirect_to_statistics(notice: nil, alert: nil)
      redirect_to admin_statistics_path(city: @city.slug, game_format: @game_format.key),
                  notice: notice,
                  alert: alert
    end
  end
end
