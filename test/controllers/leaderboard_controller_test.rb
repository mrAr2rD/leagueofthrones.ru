require "test_helper"

class LeaderboardControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get city_leaderboard_url(cities(:moscow))
    assert_response :success
    assert_select "h1", /Игра Престолов/
    assert_select "a[href=?]", city_tides_of_battle_path(cities(:moscow)), text: "Перевес"
  end

  test "shows player names" do
    get city_leaderboard_url(cities(:moscow))
    assert_match "samzakharov", response.body
  end

  test "shows the dragons column for a mother of dragons city" do
    get city_leaderboard_url(cities(:moscow))
    assert_response :success
    assert_match "Драконы", response.body
  end

  test "hides the dragons column for a classic city" do
    get city_leaderboard_url(cities(:spb))
    assert_response :success
    assert_no_match "Драконы", response.body
  end

  test "hides players without tournament participation" do
    visible = Player.create!(first_name: "Публичный", nickname: "@public_board")
    hidden = Player.create!(first_name: "Скрытый", nickname: "@hidden_board", participates_in_tournament: false)
    PlayerCity.create!(player: visible, city: cities(:moscow))
    PlayerCity.create!(player: hidden, city: cities(:moscow))

    get city_leaderboard_url(cities(:moscow))

    assert_match "public_board", response.body
    assert_no_match "hidden_board", response.body
  end

  test "scopes the leaderboard to the city" do
    spb_player = Player.create!(first_name: "Питерец", nickname: "@spb_only")
    PlayerCity.create!(player: spb_player, city: cities(:spb))

    get city_leaderboard_url(cities(:moscow))
    assert_no_match "spb_only", response.body

    get city_leaderboard_url(cities(:spb))
    assert_match "spb_only", response.body
  end

  test "a player linked to two cities appears in both leaderboards" do
    player = Player.create!(first_name: "Двугородний", nickname: "@two_cities_board")
    PlayerCity.create!(player: player, city: cities(:moscow))
    PlayerCity.create!(player: player, city: cities(:spb))

    get city_leaderboard_url(cities(:moscow))
    assert_match "two_cities_board", response.body

    get city_leaderboard_url(cities(:spb))
    assert_match "two_cities_board", response.body
  end

  test "shows a city switcher linking to other cities" do
    get city_leaderboard_url(cities(:moscow))

    assert_select "[data-testid=city-switcher]"
    assert_select "[data-testid=city-switcher] a[href=?]", city_leaderboard_path(cities(:spb))
  end

  test "shows published city achievement icons next to a player nickname" do
    player = players(:daenerys)
    published_at = Time.zone.parse("2026-07-10 12:00")
    create_award(player: player, achievement_key: "conqueror", stat_value: 4, published_at: published_at)
    create_award(player: player, achievement_key: "faceless_chosen", stat_value: 7, published_at: published_at)

    get city_leaderboard_url(cities(:moscow))

    assert_response :success
    assert_select ".player-achievement-badge[data-achievement-key=conqueror] img[src*='achievements/conqueror']", count: 1
    assert_select ".player-achievement-badge[data-achievement-key=faceless_chosen] img[src*='achievements/faceless_chosen']", count: 1
    assert_select ".player-achievement-badge[title*='Завоеватель'][title*='Больше всего захваченных чужих столиц']", count: 1
  end

  test "hides unpublished and other city achievement icons" do
    player = players(:daenerys)
    create_award(player: player, achievement_key: "faceless_chosen", stat_value: 7, published_at: nil)
    create_award(
      player: player,
      city: cities(:spb),
      achievement_key: "dragon_slayer",
      stat_value: 9,
      published_at: Time.zone.parse("2026-07-10 12:00")
    )

    get city_leaderboard_url(cities(:moscow))

    assert_response :success
    assert_select ".player-achievement-badge", count: 0
    assert_no_match "Избранник Безликих", response.body
  end

  test "redirects to the city selector for an unknown city" do
    get city_leaderboard_url("nonexistent-city")

    assert_redirected_to root_url
    assert_equal "Город не найден", flash[:alert]
  end

  test "hides the city switcher when only one city exists" do
    City.where.not(id: cities(:moscow).id).destroy_all

    get city_leaderboard_url(cities(:moscow))

    assert_select "[data-testid=city-switcher]", count: 0
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
