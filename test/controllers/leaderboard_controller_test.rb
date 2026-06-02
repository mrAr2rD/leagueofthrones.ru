require "test_helper"

class LeaderboardControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get city_leaderboard_url(cities(:moscow))
    assert_response :success
    assert_select "h1", /Игра Престолов/
  end

  test "shows player names" do
    get city_leaderboard_url(cities(:moscow))
    assert_match "samzakharov", response.body
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
end
