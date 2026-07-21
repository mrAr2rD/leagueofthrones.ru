require "test_helper"
require "date"

class PlayersControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get city_player_url(cities(:moscow), players(:daenerys))
    assert_response :success
    assert_match "Семён", response.body
    assert_no_match "Участие в турнире", response.body
  end

  test "profile shows dragons for a mother of dragons city" do
    get city_player_url(cities(:moscow), players(:daenerys))
    assert_response :success
    assert_match "Драконы", response.body
  end

  test "profile hides dragons for a classic city" do
    player = Player.create!(first_name: "Питерец", nickname: "@spb_profile")
    PlayerCity.create!(player: player, city: cities(:spb))
    tour = Tour.create!(number: 1, city: cities(:spb), format: "classic", played: true, played_on: Date.new(2026, 1, 7))
    game = Game.create!(tour: tour, table_letter: "A")
    GameResult.create!(game: game, player: player, house: "stark", place: 1, points: 12, capitals: 0, dragons: 0, castles: 0)

    get city_player_url(cities(:spb), player)

    assert_response :success
    assert_match "Старк", response.body # профиль отрисован (есть результаты)
    assert_no_match "Драконы", response.body
  end

  test "show uses captures wording and history values" do
    player = Player.create!(first_name: "Профиль", nickname: "@profile_captures")
    PlayerCity.create!(player: player, city: cities(:moscow))
    tour = tours(:tour_two)
    game = Game.create!(tour: tour, table_letter: "A")
    extra_tour = Tour.create!(number: 3, city: cities(:moscow), played: true, played_on: Date.new(2026, 1, 21))
    extra_game = Game.create!(tour: extra_tour, table_letter: "A")

    GameResult.create!(
      game: game,
      player: player,
      house: "stark",
      place: 1,
      points: 20,
      capitals: 99,
      capital_captures: 1,
      capital_controls: 2,
      dragons: 0,
      castles: 4
    )

    GameResult.create!(
      game: extra_game,
      player: player,
      house: "targaryen",
      place: 2,
      points: 10,
      capitals: 0,
      dragons: 1,
      castles: 2
    )

    get city_player_url(cities(:moscow), player)
    assert_response :success
    assert_match "Дом", response.body
    assert_match "Захваты", response.body
    assert_match "icon-capture", response.body
    assert_no_match "Столицы", response.body

    document = Nokogiri::HTML(response.body)
    summary_cards = document.css(".player-summary-item").map { |node| node.text.squish }
    history_rows = document.css("table.player-stats-table tbody tr").map do |row|
      row.css("td").map { |node| node.text.squish }
    end

    assert_includes summary_cards, "1 Захваты"
    assert_equal [ "2", "A", "Старк" ], history_rows.first.first(3)
    assert_equal "1", history_rows.first[5]
    assert_equal "4", history_rows.first[7]
    assert_equal [ "3", "A", "Таргариен" ], history_rows.second.first(3)
    assert_equal "2", history_rows.second[7]
  end

  test "show stays public for inactive player and hides participation flag" do
    player = Player.create!(first_name: "Скрытый", nickname: "@hidden_profile", participates_in_tournament: false)
    PlayerCity.create!(player: player, city: cities(:moscow))

    get city_player_url(cities(:moscow), player)

    assert_response :success
    assert_match "Скрытый", response.body
    assert_no_match "Участие в турнире", response.body
  end

  test "profile shows only results from the visited city" do
    player = Player.create!(first_name: "Гастролёр", nickname: "@traveller")
    PlayerCity.create!(player: player, city: cities(:moscow))
    PlayerCity.create!(player: player, city: cities(:spb))

    moscow_game = Game.create!(tour: tours(:tour_one), table_letter: "C")
    GameResult.create!(game: moscow_game, player: player, house: "stark", place: 1, points: 12, capitals: 0, dragons: 0, castles: 0)

    spb_tour = Tour.create!(number: 1, city: cities(:spb), format: "classic", played: true, played_on: Date.new(2026, 2, 1))
    spb_game = Game.create!(tour: spb_tour, table_letter: "A")
    GameResult.create!(game: spb_game, player: player, house: "martell", place: 1, points: 12, capitals: 0, dragons: 0, castles: 0)

    get city_player_url(cities(:moscow), player)
    assert_match "Старк", response.body
    assert_no_match "Мартелл", response.body

    get city_player_url(cities(:spb), player)
    assert_match "Мартелл", response.body
    assert_no_match "Старк", response.body
  end

  test "shows a city switcher on the profile" do
    get city_player_url(cities(:moscow), players(:daenerys))

    assert_select "[data-testid=city-switcher] a[href=?]", city_leaderboard_path(cities(:spb))
  end

  test "shows only published achievements from the visited city" do
    player = players(:daenerys)
    create_award(
      player: player,
      achievement_key: "conqueror",
      stat_value: 3,
      published_at: Time.zone.parse("2026-07-10 12:00")
    )
    create_award(
      player: player,
      achievement_key: "faceless_chosen",
      stat_value: 8,
      published_at: nil
    )
    create_award(
      player: player,
      city: cities(:spb),
      achievement_key: "dragon_slayer",
      stat_value: 99,
      published_at: Time.zone.parse("2026-07-10 12:00")
    )

    get city_player_url(cities(:moscow), player)

    assert_response :success
    assert_select "[data-testid=player-achievements]"
    assert_select "[data-achievement-key=conqueror]", count: 1
    assert_select "[data-achievement-key=faceless_chosen]", count: 0
    assert_select "[data-achievement-key=dragon_slayer]", count: 0
    assert_no_match "Избранник Безликих", response.body
  end

  test "shows multiple achievement snapshots with format descriptions and values" do
    player = players(:daenerys)
    published_at = Time.zone.parse("2026-07-10 12:00")
    create_award(player: player, achievement_key: "conqueror", stat_value: 3, published_at: published_at)
    create_award(player: player, achievement_key: "dragon_slayer", stat_value: 5, published_at: published_at)
    create_award(player: player, achievement_key: "faceless_chosen", stat_value: 7, published_at: published_at)

    get city_player_url(cities(:moscow), player)

    assert_select "[data-achievement-key=conqueror]", text: /Завоеватель.*результат: 3/m
    assert_select "[data-achievement-key=dragon_slayer]", text: /Драконоборец.*результат: 5/m
    assert_select "[data-achievement-key=faceless_chosen]", text: /Избранник Безликих.*результат: 7/m
    assert_select "[data-achievement-key=conqueror] img[src*='achievements/conqueror']", count: 1
    assert_select "[data-achievement-key=dragon_slayer] img[src*='achievements/dragon_slayer']", count: 1
    assert_select "[data-achievement-key=faceless_chosen] img[src*='achievements/faceless_chosen']", count: 1
    assert_match "Мать драконов (8 игроков)", response.body
    assert_match "Больше всего захваченных чужих столиц", response.body
  end

  test "shows an achievement to every joint winner" do
    published_at = Time.zone.parse("2026-07-10 12:00")
    create_award(player: players(:daenerys), achievement_key: "conqueror", stat_value: 4, published_at: published_at)
    create_award(player: players(:jon), achievement_key: "conqueror", stat_value: 4, published_at: published_at)

    get city_player_url(cities(:moscow), players(:daenerys))
    assert_select "[data-achievement-key=conqueror]", count: 1

    get city_player_url(cities(:moscow), players(:jon))
    assert_select "[data-achievement-key=conqueror]", count: 1
  end

  private

  def create_award(player:, achievement_key:, stat_value:, published_at:, city: cities(:moscow))
    AchievementAward.create!(
      city: city,
      player: player,
      game_format: "mother_of_dragons",
      achievement_key: achievement_key,
      stat_value: stat_value,
      awarded_at: Time.zone.parse("2026-07-10 12:00"),
      published_at: published_at,
      awarded_by: admin_users(:admin)
    )
  end
end
