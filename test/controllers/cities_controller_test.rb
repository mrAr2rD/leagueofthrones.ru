require "test_helper"

class CitiesControllerTest < ActionDispatch::IntegrationTest
  test "root redirects to the default city leaderboard" do
    # Москва имеет position 0, СПб — 1, поэтому дефолт — Москва.
    get root_url

    assert_redirected_to city_leaderboard_url(cities(:moscow))
  end

  test "root redirects to the only city when a single one exists" do
    City.where.not(id: cities(:moscow).id).destroy_all

    get root_url

    assert_redirected_to city_leaderboard_url(cities(:moscow))
  end

  test "shows an empty state when no cities exist" do
    City.destroy_all

    get root_url

    assert_response :success
    assert_match "Города ещё не созданы", response.body
  end
end
