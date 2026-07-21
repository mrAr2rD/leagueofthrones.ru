require "test_helper"
require "securerandom"

module Admin
  class StatisticsControllerTest < ActionDispatch::IntegrationTest
    test "superadmin sees every city and defaults to the first city format" do
      login_as(admin_users(:admin))

      get admin_statistics_url

      assert_response :success
      assert_select "select#city option", count: City.count
      assert_select "select#city option[selected][value=?]", cities(:moscow).slug
      assert_select "select#game_format option[selected][value=?]", cities(:moscow).default_format
    end

    test "regular admin sees only assigned cities" do
      login_as(admin_users(:city_admin))

      get admin_statistics_url

      assert_response :success
      assert_select "select#city option", count: 1
      assert_select "select#city option[value=?]", cities(:moscow).slug
      assert_select "select#city option[value=?]", cities(:spb).slug, count: 0
    end

    test "regular admin without assigned cities is redirected without an error" do
      admin = AdminUser.create!(
        login: "statistics_admin_without_city",
        password: "password",
        superadmin: false
      )
      login_as(admin)

      get admin_statistics_url

      assert_redirected_to admin_root_url
      assert_equal "Нет доступных городов", flash[:alert]
    end

    test "regular admin cannot read another city statistics" do
      login_as(admin_users(:city_admin))

      get admin_statistics_url(city: cities(:spb).slug, game_format: "classic")

      assert_redirected_to admin_root_url
      assert_equal "Нет доступа к этому городу", flash[:alert]
    end

    test "classic statistics hide dragon and skull columns and nominations" do
      login_as(admin_users(:admin))

      get admin_statistics_url(city: cities(:spb).slug, game_format: "classic")

      assert_response :success
      assert_match "Завоеватель", response.body
      assert_no_match "Драконоборец", response.body
      assert_no_match "Избранник Безликих", response.body
      assert_no_match ">Драконы<", response.body
      assert_no_match ">Черепки<", response.body
    end

    test "statistics renders separate responsive desktop table and mobile player cards" do
      login_as(admin_users(:admin))
      tournament = create_complete_tournament

      get admin_statistics_url(city: tournament[:city].slug, game_format: "mother_of_dragons")

      assert_response :success
      assert_select "[data-testid=statistics-desktop-table]" do |nodes|
        assert_includes nodes.first["class"].split, "hidden"
        assert_includes nodes.first["class"].split, "md:block"
      end
      assert_select "[data-testid=statistics-desktop-table] table" do |nodes|
        assert_includes nodes.first["class"].split, "w-full"
        assert_includes nodes.first["class"].split, "min-w-[42rem]"
      end
      assert_select "[data-testid=statistics-mobile-players]" do |nodes|
        assert_includes nodes.first["class"].split, "md:hidden"
      end
      assert_select "[data-testid=statistics-mobile-player]", count: 8
      assert_select "[data-testid=statistics-mobile-players] dt", text: "Захваты столиц", minimum: 1
      assert_select "[data-testid=statistics-mobile-players] dt", text: "Драконы", minimum: 1
      assert_select "[data-testid=statistics-mobile-players] dt", text: "Черепки", minimum: 1
      assert_select "[data-achievement-key=conqueror] img[src*='achievements/conqueror']", count: 1
      assert_select "[data-achievement-key=dragon_slayer] img[src*='achievements/dragon_slayer']", count: 1
      assert_select "[data-achievement-key=faceless_chosen] img[src*='achievements/faceless_chosen']", count: 1
    end

    test "publication is rejected when tournament data is incomplete" do
      login_as(admin_users(:admin))

      assert_no_difference -> { AchievementAward.count } do
        post admin_statistics_achievements_publish_url, params: {
          city_id: cities(:moscow).id,
          game_format: "mother_of_dragons"
        }
      end

      assert_redirected_to admin_statistics_url(city: "moscow", game_format: "mother_of_dragons")
      assert_match "Публикация невозможна", flash[:alert]
    end

    test "publication saves all joint leaders and value snapshots" do
      login_as(admin_users(:admin))
      tournament = create_complete_tournament

      post_publication(tournament[:city])

      awards = published_awards(tournament[:city])
      assert_equal 4, awards.size
      assert_equal tournament[:players].first(2).map(&:id).sort,
                   awards.select { |award| award.achievement_key == "conqueror" }.map(&:player_id).sort
      assert_equal [ 2 ], awards.select { |award| award.achievement_key == "conqueror" }.map(&:stat_value).uniq
      assert_equal [ tournament[:players].first.id ],
                   awards.select { |award| award.achievement_key == "dragon_slayer" }.map(&:player_id)
      assert_equal [ tournament[:players].second.id ],
                   awards.select { |award| award.achievement_key == "faceless_chosen" }.map(&:player_id)
      assert awards.all? { |award| award.awarded_by == admin_users(:admin) }
      assert awards.all? { |award| award.awarded_at.present? && award.published_at.present? }
    end

    test "publication ignores forged player and stat params" do
      login_as(admin_users(:admin))
      tournament = create_complete_tournament
      forged_player = players(:daenerys)

      post admin_statistics_achievements_publish_url, params: {
        city_id: tournament[:city].id,
        game_format: "mother_of_dragons",
        player_id: forged_player.id,
        stat_value: 999
      }

      awards = published_awards(tournament[:city])
      assert_not_includes awards.map(&:player_id), forged_player.id
      assert_not_includes awards.map(&:stat_value), 999
    end

    test "refresh atomically replaces the published winner set" do
      login_as(admin_users(:admin))
      tournament = create_complete_tournament
      post_publication(tournament[:city])
      previous_winner_ids = tournament[:players].first(2).map(&:id)

      new_winner = tournament[:results].third
      new_winner.update!(capital_captures: 5, capital_controls: 0)

      patch admin_statistics_achievements_refresh_url, params: {
        city_id: tournament[:city].id,
        game_format: "mother_of_dragons"
      }

      conqueror_awards = published_awards(tournament[:city]).select do |award|
        award.achievement_key == "conqueror"
      end
      assert_equal [ new_winner.player_id ], conqueror_awards.map(&:player_id)
      assert_equal [ 5 ], conqueror_awards.map(&:stat_value)
      previous_awards = AchievementAward.where(
        city: tournament[:city],
        game_format: "mother_of_dragons",
        achievement_key: "conqueror",
        player_id: previous_winner_ids
      )
      assert_equal 2, previous_awards.count
      assert previous_awards.all? { |award| award.published_at.nil? }
    end

    test "unpublish hides awards without deleting them" do
      login_as(admin_users(:admin))
      tournament = create_complete_tournament
      post_publication(tournament[:city])
      total_count = AchievementAward.count

      delete admin_statistics_achievements_unpublish_url, params: {
        city_id: tournament[:city].id,
        game_format: "mother_of_dragons"
      }

      assert_equal total_count, AchievementAward.count
      assert_empty published_awards(tournament[:city])
      assert AchievementAward.where(city: tournament[:city]).all? { |award| award.published_at.nil? }
    end

    test "regular admin cannot publish another city awards" do
      login_as(admin_users(:city_admin))

      assert_no_difference -> { AchievementAward.count } do
        post admin_statistics_achievements_publish_url, params: {
          city_id: cities(:spb).id,
          game_format: "classic"
        }
      end

      assert_redirected_to admin_root_url
    end

    test "saved awards stay unchanged after results change and page warns about the difference" do
      login_as(admin_users(:admin))
      tournament = create_complete_tournament
      post_publication(tournament[:city])
      published_value = AchievementAward.find_by!(
        city: tournament[:city],
        achievement_key: "conqueror",
        player: tournament[:players].first
      ).stat_value

      tournament[:results].third.update!(capital_captures: 7, capital_controls: 0)

      assert_equal published_value, AchievementAward.find_by!(
        city: tournament[:city],
        achievement_key: "conqueror",
        player: tournament[:players].first
      ).stat_value

      get admin_statistics_url(city: tournament[:city].slug, game_format: "mother_of_dragons")
      assert_select "[data-testid=published-awards-diff]"
    end

    private

    def login_as(user)
      post admin_login_url, params: { login: user.login, password: "password" }
    end

    def post_publication(city)
      post admin_statistics_achievements_publish_url, params: {
        city_id: city.id,
        game_format: "mother_of_dragons"
      }
    end

    def published_awards(city)
      AchievementAward.for_tournament(city: city, game_format: "mother_of_dragons").published.order(:id).to_a
    end

    def create_complete_tournament
      city = City.create!(
        name: "Город публикации",
        slug: "publication-#{SecureRandom.hex(5)}",
        default_format: "mother_of_dragons"
      )
      tour = Tour.create!(
        city: city,
        number: 1,
        format: "mother_of_dragons",
        tables_count: 1,
        played: true,
        played_on: Date.new(2026, 7, 1)
      )
      game = Game.create!(tour: tour, table_letter: "A")
      players = 8.times.map do |index|
        Player.create!(
          first_name: "Победитель #{index + 1}",
          nickname: "@publication_#{SecureRandom.hex(5)}"
        )
      end
      stats = [
        { capitals: 2, dragons: 3, skulls: 1 },
        { capitals: 2, dragons: 1, skulls: 4 },
        { capitals: 1, dragons: 0, skulls: 0 },
        { capitals: 0, dragons: 0, skulls: 0 },
        { capitals: 0, dragons: 0, skulls: 0 },
        { capitals: 0, dragons: 0, skulls: 0 },
        { capitals: 0, dragons: 0, skulls: 0 },
        { capitals: 0, dragons: 0, skulls: 0 }
      ]
      results = players.each_with_index.map do |player, index|
        GameResult.create!(
          game: game,
          player: player,
          house: GameFormat.default.house_keys.fetch(index),
          place: index + 1,
          points: 20 - index,
          capitals: stats.fetch(index).fetch(:capitals),
          lands: 0,
          skulls: stats.fetch(index).fetch(:skulls),
          dragons: stats.fetch(index).fetch(:dragons),
          castles: 0
        )
      end

      { city: city, tour: tour, game: game, players: players, results: results }
    end
  end
end
