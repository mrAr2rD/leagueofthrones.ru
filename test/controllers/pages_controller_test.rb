require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "renders the city rules page" do
    get city_rules_url(cities(:moscow))

    assert_response :success
    assert_match "Правила турнира в Москве", response.body
  end

  test "rules are scoped per city" do
    get city_rules_url(cities(:spb))

    assert_response :success
    assert_match "Санкт-Петербурге", response.body
    assert_no_match "в Москве", response.body
  end

  test "shows a city switcher on the rules page" do
    get city_rules_url(cities(:moscow))

    assert_select "[data-testid=city-switcher] a[href=?]", city_leaderboard_path(cities(:spb))
  end
end
